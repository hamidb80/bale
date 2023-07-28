## https://dev.bale.ai/api

import std/[asyncdispatch, httpclient, uri]
import std/[json, options, strutils]
import bale/private/utils

type
  UriQuery = tuple[key: string, value: string]

  Array[T] = seq[T]

  BaleBot = object
    apiRoot: Uri
    lastUpdateId: int

  BaleError = ref object of CatchableError
    code: int
    # msg: string (description) - inherits this field

  BaleResult* = distinct JsonNode
  BaleIntResult* = distinct BaleResult
  BaleBoolResult* = distinct BaleResult
  GetUpdatesResult* = distinct BaleResult
  GetFileResult* = distinct BaleResult
  BaleMessageResult* = distinct BaleResult
  GetChatAdministratorsResult* = distinct BaleResult
  GetChatResult* = distinct BaleResult
  GetUserResult* = distinct BaleResult
  GetChatMemberResult* = distinct BaleResult

  Update* = distinct JsonNode
  User* = distinct JsonNode
  MessageEntity* = distinct JsonNode
  BFile* = distinct JsonNode
  Chat* = distinct JsonNode
  Invoice* = distinct JsonNode
  ChatMember* = distinct JsonNode
  Audio* = distinct JsonNode
  Document* = distinct JsonNode
  PhotoSize* = distinct JsonNode
  Video* = distinct JsonNode
  Voice* = distinct JsonNode
  Contact* = distinct JsonNode
  Location* = distinct JsonNode
  Message* = distinct JsonNode
  CallbackQuery* = distinct JsonNode
  ShippingQuery* = distinct JsonNode
  PreCheckoutQuery* = distinct JsonNode
  SuccessfulPayment* = distinct JsonNode

  ReplyKeyboardMarkup* = distinct JsonNode

  ChatTypes* = enum
    ctPrivate = "private"
    ctGroup = "group"
    ctSuperGroup = "supergroup"
    ctChannel = "channel"

  UserChatStatus* = enum
    ucsCreator = "creator"
    ucsAdministrator = "administrator"
    ucsMember = "member"
    ucsRestricted = "restricted"
    ucsLeft = "left"
    ucsKicked = "kicked"

# -------------------------------

defFields Update, {
  (update_id, id): int,
  (message, msg): Option[Message],
  (edited_message, edited_msg): Option[Message],
  (channel_post, channp): Option[Message],
  (edited_channel_post, edited_channp): Option[Message],
  (callback_query, cbq): Option[CallbackQuery],
  (shipping_query, shq): Option[ShippingQuery],
  (pre_checkout_query, pckq): Option[PreCheckoutQuery]}

defFields User, {
  id: int,
  username: string,
  first_name: string,
  last_name: string,
  language_code: Option[string],
  is_bot: bool}

defFields Message, {
  (message_id, id): int,
  (`from`, frm): User,
  date: int,
  chat: Chat,
  text: Option[string],
  forwarded_from: Option[User],
  forwarded_from_chat: Option[Chat],
  forwarded_from_message_id: Option[int],
  forwarded_date: Option[int],
  reply_to: Option[Message],
  edit_date: Option[int],
  entities: Option[Array[MessageEntity]],
  caption_entities: Option[Array[MessageEntity]],
  audio: Option[Audio],
  document: Option[Document],
  photo: Option[Array[PhotoSize]],
  video: Option[Video],
  voice: Option[Voice],
  caption: Option[string],
  contact: Option[Contact],
  location: Option[Location],
  new_chat_members: Option[Array[User]],
  left_chat_memeber: Option[User],
  new_chat_title: Option[string],
  new_chat_photo: Option[Array[PhotoSize]],
  delete_chat_photo: Option[bool],
  group_chat_created: Option[bool],
  supergroup_chat_created: Option[bool],
  channel_chat_created: Option[bool],
  pinned_message: Option[Message],
  invoice: Option[Invoice],
  successful_payment: Option[SuccessfulPayment],
  edited_message: Option[Message],
  channel_post: Option[Message],
  edited_channel_post: Option[Message],
  callback_query: Option[CallbackQuery],
  shipping_query: Option[ShippingQuery],
  pre_checkout_query: Option[PreCheckoutQuery]}

defFields BFile, {
  (file_id, id): string,
  (file_size, size): int,
  (file_path, path): string}

defFields Chat, {
  id: int,
  (`type`, typ): Enum[ChatTypes],
  title: string,
  username: string,
  first_name: string,
  last_name: string,
  all_members_are_administrators: bool,
  description: string,
  invite_link: string,
  pinned_message: Option[Message],
  sticker_set_name: string,
  can_set_sticker_set: bool}

defFields ChatMember, {
  user: User,
  status: Enum[UserChatStatus],
  until_date: int,
  can_be_edited: bool,
  can_change_info: bool,
  can_post_messages: bool,
  can_edit_messages: bool,
  can_delete_messages: bool,
  can_invite_users: bool,
  can_restrict_members: bool,
  can_pin_messages: bool,
  can_promote_members: bool,
  can_send_messages: bool,
  can_send_media_messages: bool,
  can_send_other_messages: bool,
  can_add_web_page_previews: bool}


defFields BaleResult, {
  error_code: Option[int],
  ok: bool,
  description: string}

template defResultType(ObjName, ResultType): untyped {.dirty.} =
  defFields ObjName, {
    (result, res): ResultType,
    ...BaleResult{ok, error_code, description}}


defResultType BaleBoolResult, bool
defResultType BaleIntResult, int
defResultType BaleMessageResult, Message
defResultType GetUpdatesResult, Array[Update]
defResultType GetFileResult, BFile
defResultType GetChatAdministratorsResult, Array[ChatMember]
defResultType GetUserResult, User
defResultType GetChatResult, Chat
defResultType GetChatMemberResult, ChatMember

# -------------------------------

proc newBaleBot*(token: string): BaleBot =
  BaleBot(
    apiRoot: parseUri "https://tapi.bale.ai/bot" & token,
    lastUpdateId: -1)


func initQuery*: seq[UriQuery] = @[]
const noQuery = initQuery()

template newBaleError(ecode, desc): untyped =
  let err = new BaleError
  err.code = ecode
  err.msg = desc
  err

template assertOkRaw(res): untyped =
  if not res.ok:
    raise newBaleError(res.error_code.get 0, res.description)

template assertOkTemp(resp): untyped =
  let r = resp
  assertOkRaw r

template assertOkSelf(resp): untyped =
  let r = resp
  assertOkRaw r
  r.result()


# -------------------------------

proc sendMessage*(b: BaleBot,
  chat_id: int,
  text: string,
  reply_markup: Option[ReplyKeyboardMarkup] = none ReplyKeyboardMarkup,
  reply_to_message_id: int = -1,
): Future[Message] {.addProcName, async.} =
  var payload = %*{"chat_id": chat_id, "text": text}

  # if reply_markup.isSome:
  #   payload["reply_markup"] = %reply_markup.get

  if reply_to_message_id != -1:
    payload["reply_to_message_id"] = %reply_to_message_id

  return assertOkSelf BaleMessageResult postc payload

proc editMessageText*(b: BaleBot,
  chat_id, message_id: int,
  text: string,
  reply_markup: Option[ReplyKeyboardMarkup] = none ReplyKeyboardMarkup,
): Future[Message] {.addProcName, async.} =
  var payload = %*{"chat_id": chat_id, "message_id": message_id, "text": text}

  # if reply_markup.isSome:
  #   payload["reply_markup"] = %reply_markup.get

  return assertOkSelf BaleMessageResult postc payload

proc deleteMessage*(b: BaleBot, chat_id, message_id: int) {.addProcName, async.} =
  assertOkTemp BaleBoolResult getc toQuery {chat_id, message_id}

proc setWebhook*(b: BaleBot, url: string) {.addProcName, async.} =
  assertOkTemp BaleBoolResult postc url

proc deleteWebhook*(b: BaleBot) {.addProcName, async.} =
  assertOkTemp BaleBoolResult getc noQuery

proc getUpdates*(b: BaleBot, offset, limit: int = -1):
  Future[seq[Update]] {.addProcName, queryFields, async.} =
  return assertOkSelf GetUpdatesResult getc toQuery {!offset, !limit}

proc getFile*(b: BaleBot, fileId: string):
  Future[BFile] {.addProcName, async.} =
  return assertOkSelf GetFileResult getc toQuery {file_id}

proc getMe*(b: BaleBot): Future[User] {.addProcName, async.} =
  return assertOkSelf GetUserResult getc noQuery

proc getChat*(b: BaleBot, chat_id: int):
  Future[Chat] {.addProcName, async.} =
  return assertOkSelf GetChatResult getc toQuery {chat_id}

proc getChatAdministrators*(b: BaleBot, chat_id: int):
  Future[seq[ChatMember]] {.addProcName, async.} =
  return assertOkSelf GetChatAdministratorsResult getc toQuery {chat_id}

proc getChatMembersCount*(b: BaleBot, chat_id: int):
  Future[int] {.addProcName, async.} =
  return assertOkSelf BaleIntResult getc toQuery {chat_id}

proc getChatMember*(b: BaleBot, chat_id, user_id: int):
  Future[ChatMember] {.addProcName, async.} =
  return assertOkSelf GetChatMemberResult getc toQuery {chat_id, user_id}


proc sendPhoto*(b: BaleBot,
  chat_id: int,
  caption: string,
  photo: string,
  from_file: bool,
  reply_to_message_id: int = -1
): Future[Message] {.addProcName, queryFields, async.} =
  var m = newMultipartData toQuery {chat_id, caption, !reply_to_message_id}
  if from_file:
    m.addFiles {"photo": photo}
  else:
    m.add("photo", photo)
  echo m
  # let m = %*{
  #   "chat_id": chat_id,
  #   "caption": caption,
  #   "photo": photo}
  return assertOkSelf BaleMessageResult postc m


# sendAudio
# sendDocument
# sendVideo
# sendVoice
# sendLocation
# sendInvoice
