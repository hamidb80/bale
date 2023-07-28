import std/[macros, json, options, strutils, httpcore]
import macroplus

func isNull*(j: JsonNode): bool =
  j != nil or j.kind == JNull

template conv*[T: int or string or bool](j: JsonNode, t: typedesc[T]): untyped =
  j.to t

template conv*[T: enum](j: JsonNode, t: typedesc[T]): untyped =
  parseEnum[t](j.getStr)

template conv*[T](j: JsonNode, t: typedesc[seq[T]]): untyped =
  cast[seq[T]](j.elems)

template conv*[T](j: JsonNode, t: typedesc[Option[T]]): untyped =
  j.to Option[T]

template conv*(j: JsonNode, t): untyped =
  cast[t](j)

template invalid(msg): untyped =
  raise newException(ValueError, msg)

func `[]`(n: NimNode, s: Hslice[int, BackwardsIndex]): seq[NimNode] =
  for i in s.a .. (n.len - s.b.int):
    result.add n[i]

func literalStrVal*(n: NimNode): string =
  case n.kind
  of nnkIdent: n.strVal
  of nnkAccQuoted: n[0].strVal
  else: invalid "errr ?"

func exported(n: NimNode): NimNode =
  postfix n, "*"

macro defFields*(jsonType, bodyFields): untyped =
  expectKind bodyFields, {nnkTableConstr, nnkCurly}
  result = newStmtList()

  for e in bodyFields:
    case e.kind
    of nnkExprColonExpr:
      let
        (key, aliases) = block:
          let t = e[0]

          case t.kind
          of nnkIdent, nnkAccQuoted: (t, @[])
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

            of "Option": t
            of "Enum": valueType
            else: invalid "invalid Wrapper: " & $key
          else: invalid "invalid kind: " & $key

        kstr = newLit literalStrVal key
        arg = ident "arg"
        body = quote:
          `arg`.JsonNode[`kstr`].conv `type`

      result.add newProc(
        exported key,
        [`type`, newIdentDefs(arg, jsonType)],
        body,
        nnkFuncDef)

      for a in aliases:
        let b = quote:
          `key`(`arg`)

        result.add newProc(
          exported a,
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
          exported f,
          [a, newIdentDefs(arg, jsonType)],
          body,
          nnkFuncDef)
    else: invalid "invalid field: " & $e.kind

  # debugEcho repr result

macro queryFields*(procDef): untyped =
  var
    body = procDef.body
    ps = procDef.params
    paramsWithDefaults: seq[tuple[name, defaultName: string]]
    q = ident "query"

  body.insert 0, quote do:
    var `q` = initQuery()

  for i in 1..<ps.len:
    let
      p = ps[i]
      d = p[IdentDefDefaultVal]

    if d.kind != nnkEmpty:
      for x in p[IdentDefNames]:
        let
          name = x.literalStrVal
          dname = name & "Default"
          id = ident dname

        paramsWithDefaults.add (name, dname)
        body.insert 0, quote do:
          let `id` {.global.} = `d`

  for (p, d) in paramsWithDefaults:
    let
      pi = ident p
      ps = newLit p
      di = ident d

    body.insert paramsWithDefaults.len+1, quote do:
      if `pi` != `di`:
        `q`.add (`ps`, $`di`)

  return procDef
  # debugEcho repr body

macro addProcName*(procDef): untyped =
  let
    name = procDef.name.strVal
    str = newlit:
      if name.toLowerAscii.endsWith "impl": name[1..^5]
      else: name

    id = ident "procname"

  procDef.body.insert 0, quote do:
    const `id` = `str`

  return procDef


template apiUrl*: untyped {.dirty.} =
  b.apiRoot / procname

# template checkHttpError(resp): untyped =
#   if resp.code.is4xx or resp.code.is5xx:
#     raise newException(HttpRequestError, resp.status)
  
# TODO think more about exceptions ...

template getc*(queryParams): untyped {.dirty.} =
  let c = newAsyncHttpClient()
  defer: c.close()
  let res = await c.request(apiUrl ? queryParams, HttpGet)
  parseJson await res.body

template postc*(content): untyped {.dirty.} =
  let c = newAsyncHttpClient()
  defer: c.close()
  let
    kind =
      when content is JsonNode: "application/json"
      else: "multipart/form-data"
    res = await c.request(apiUrl, HttpPost,
      body = $content,
      headers = newHttpHeaders {"content-type": kind})

  parseJson await res.body


func curlyToTableConstr(n: NimNode): NimNode =
  expectKind n, nnkCurly
  result = newNimNode nnkTableConstr
  for e in n:
    result.add newColonExpr(e.strVal.newLit, newCall(ident"$", e))

macro toQuery*(node): untyped =
  return curlyToTableConstr node
