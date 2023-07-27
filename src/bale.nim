import std/[asyncdispatch, httpclient, uri]
import std/[json, strformat, options]

import std/macros, macroplus, caster

type
  UriQuery = tuple[key: string, value: string]

  BaleBot = object
    apiRoot: Uri
    lastUpdateId: int

  BaleResult = distinct JsonNode
  Update = distinct BaleResult
  GetUpdateResult = distinct BaleResult
  Message = distinct BaleResult

  ChatTypes = enum
    ctPrivate = "private"
    ctGroup = "group"
    ctSuperGroup = "supergroup"
    ctChannel = "channel"

  UserChatStatus = enum
    ucsCreator = "creator"
    ucsAdministrator = "administrator"
    ucsMember = "member"
    ucsRestricted = "restricted"
    ucsLeft = "left"
    ucsKicked = "kicked"


proc newBaleBot(token: string): BaleBot =
  BaleBot(
    apiRoot: parseUri "https://tapi.bale.ai/bot" & token,
    lastUpdateId: -1)

func initQuery: seq[UriQuery] = @[]

proc getUpdates(b: BaleBot, offset, limit = -1): Future[
    GetUpdateResult] {.async.} =
  var q = initQuery()
  if offset != -1:
    q.add ("offset", $offset)
  if limit != -1:
    q.add ("limit", $limit)

  let c = newAsyncHttpClient()
  defer: c.close
  let res = await c.getContent(b.apiRoot / "getupdates" ? q)
  return GetUpdateResult parseJson res

# setWebhook
# deleteWebhook


# ------------------

func isNull*(j: JsonNode): bool =
  j != nil or j.kind == JNull

# ------------------

template conv[T: int or string or bool](j: JsonNode, t: typedesc[T]): untyped =
  j.to t

template conv[T: enum](j: JsonNode, t: typedesc[T]): untyped =
  parseEnum[T](j.getStr)

template conv[T](j: JsonNode, t: typedesc[seq[T]]): untyped =
  cast[seq[T]](j.elems)

template invalid(msg): untyped =
  raise newException(ValueError, msg)

func `[]`(n: NimNode, s: Hslice[int, BackwardsIndex]): seq[NimNode] =
  for i in s.a .. (n.len - s.b.int):
    result.add n[i]

macro defFields(jsonType, bodyFields): untyped =
  expectKind bodyFields, {nnkTableConstr, nnkCurly}
  result = newStmtList()

  for e in bodyFields:
    case e.kind
    of nnkExprColonExpr:
      let
        (key, aliases) = block:
          let t = e[0]

          case t.kind
          of nnkIdent: (t, @[])
          of nnkTupleConstr: (t[0], t[1..^1])
          else: invalid "kind: " & $t.kind

        `type` = block:
          let t = e[1]

          case t.kind
          of nnkIdent: t
          of nnkBracketExpr:
            let
              wrapper = strVal t[0]
              valueType = t[1]

            case wrapper
            of "Array":
              quote:
                seq[`valueType`]

            # of "Option":
            #   quote:
            #     if isNull `arg`:
            #       newJNull()
            #     else:
            #       recur kind

            # of "Enum":
            #   conv `arg`, `kind`

            else: invalid "invalid Wrapper: " & $key
          else: invalid "invalid kind: " & $key

        kstr = newLit key.strVal
        arg = ident "arg"
        body = quote:
          `arg`.JsonNode[`kstr`].conv `type`

      result.add newProc(
        key,
        [`type`, newIdentDefs(arg, jsonType)],
        body,
        nnkFuncDef)

      for a in aliases:
        let b = quote:
          `key`(`arg`)

        result.add newProc(
          a,
          [`type`, newIdentDefs(arg, jsonType)],
          b,
          nnkTemplateDef)



    of nnkPrefix:
      expectIdent e[0], "..."
      expectKind e[1], nnkCurlyExpr
      let
        castedType = e[1][0]
        fields = e[1][1..^1]
        a = ident"auto"
        arg = ident"arg"

      for f in fields:
        let body = quote:
          `arg`.`castedType`.`f`

        result.add newProc(
          f,
          [a, newIdentDefs(arg, jsonType)],
          body,
          nnkFuncDef)


    else: discard

  debugEcho repr result

defFields BaleResult, {
  error_code: int,
  ok: bool,
  description: string}

defFields GetUpdateResult, {
  result: Array[Update],
  ...BaleResult{ok, error_code, description}
  }

defFields Update, {
  (update_id, id): int,
  # (message, msg): Option[Message],
  # (edited_message, edited_msg): Option[Message],
  # (channel_post, chp): Option[Message],
  # (edited_channel_post, edchp): Option[Message],
  # (callback_query, cbq): Option[CallbackQuery],
  # (shipping_query, shq): Option[ShippingQuery],
  # (pre_checkout_query, pckq): Option[PreCheckoutQuery]
  }

# defFields User, {
#   id: int,
#   username: string,
#   first_name: string,
#   last_name: string,
#   language_code: string,
#   is_bot: bool}

# defFields BFile, {
#   (file_id, id): string,
#   file_size: int,
#   file_path: string}


# defFields Chat, {
#   id: int,
#   `type`: Enum[ChatTypes],
#   title: string,
#   username: string,
#   first_name: string,
#   last_name: string,
#   all_members_are_administrators: bool,
#   description: string,
#   invite_link: string,
#   pinned_message: Option[Message],
#   sticker_set_name: string,
#   can_set_sticker_set: bool}

# defFields ChatMember, {
#   user: User,
#   status: UserChatStatus,
#   until_date: int,
#   can_be_edited: bool,
#   can_change_info: bool,
#   can_post_messages: bool,
#   can_edit_messages: bool,
#   can_delete_messages: bool,
#   can_invite_users: bool,
#   can_restrict_members: bool,
#   can_pin_messages: bool,
#   can_promote_members: bool,
#   can_send_messages: bool,
#   can_send_media_messages: bool,
#   can_send_other_messages: bool,
#   can_add_web_page_previews: bool}


when isMainModule:
  const token = staticRead "../bot.token"
  let
    bot = newBaleBot token
    updates = waitFor bot.getUpdates

  for u in updates.result:
    echo u.id
