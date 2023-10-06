import std/[json, httpclient]

type
  ContentKind* = enum
    ckNone
    ckJson
    ckMultiPart

  Content* = object
    case kind*: ContentKind
    of ckNone: discard
    of ckJson:
      j*: JsonNode
    of ckMultiPart:
      m*: MultipartData

  RequestInfo*[T] = object
    httpMethod*: HttpMethod
    url*: string
    content*: Content
    responseParser*: proc(body: string): T
