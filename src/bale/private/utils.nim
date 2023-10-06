import std/[macros, json, options, strutils, httpcore, httpclient]
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
            of "Array", "Option": t
            of "Enum": valueType
            else: invalid "invalid Wrapper: " & $key
          else: invalid "invalid kind: " & $key

        kstr = newLit literalStrVal key
        arg = ident "arg"
        body = quote:
          `arg`.JsonNode{`kstr`}.conv `type`

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

    else: invalid "invalid field: " & $e.kind

  # debugEcho repr result

macro defParamDefaults*(procDef): untyped =
  var
    body = procDef.body
    ps = procDef.params

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

        body.insert 0, quote do:
          let `id` {.global.} = `d`

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

func lastUrlPart*(u: string): string = 
  let i = u.rfind '/'
  u[i..^1]

macro toQuery*(n): untyped =
  expectKind n, nnkCurly
  let acc = ident "acc"
  result = newStmtList()
  result.add quote do:
    var `acc`: seq[(string, string)] = @[]

  for e in n:
    case e.kind
    of nnkPrefix:
      let
        (node, op) = unpackPrefix e
        nodeDefault = ident node.strVal & "Default"
        s = newLit node.strVal

      assert op == "?"

      result.add quote do:
        if `node` != `nodeDefault`:
          `acc`.add (`s`, $`node`)

    of nnkIdent:
      let s = newLit e.strVal

      result.add quote do:
        `acc`.add (`s`, $`e`)

    else:
      discard

  result.add acc
  result = newTree(nnkBlockStmt, newEmptyNode(), result)

macro toJson*(n): untyped = 
  expectKind n, nnkCurly
  let acc = ident "acc"
  result = newStmtList()
  result.add quote do:
    var `acc` = newJObject()

  for e in n:
    case e.kind
    of nnkPrefix:
      let
        (node, op) = unpackPrefix e
        nodeDefault = ident node.strVal & "Default"
        s = newLit node.strVal

      assert op == "?"

      result.add quote do:
        if `node` != `nodeDefault`:
          `acc`[`s`] = %`node`

    of nnkIdent:
      let s = newLit e.strVal

      result.add quote do:
        `acc`[`s`] = %`e`

    else: discard # XXX

  result.add acc
  result = newTree(nnkBlockStmt, newEmptyNode(), result)
  

proc addCustomFile*(m: var MultiPartData, field, file: string, isBinary: bool) =
  if isBinary:
    m.addFiles {field: file}
  else:
    m.add field, file

template multipartFile*(q, field, path, isBinary): untyped = 
  var m = newMultipartData toQuery q
  m.addCustomFile field, path, is_binary
  m