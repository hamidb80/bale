import std/[httpclient, json], asyncdispatch
import ../private/request

proc req*[T](hc: HttpClient, ri: RequestInfo[T]): T =
    ri.responseParser body do:
        case ri.content.kind
        of ckNone:
            hc.request(ri.url, ri.httpMethod)
        of ckJson:
            hc.request(ri.url, ri.httpMethod, $ri.content.j)
        of ckMultiPart:
            hc.request(ri.url, ri.httpMethod, multipart = ri.content.m)

proc req*[T](hc: AsyncHttpClient, ri: RequestInfo[T]): Future[T] {.async.} =
    return ri.responseParser await body do:
        case ri.content.kind
        of ckNone:
            await hc.request(ri.url, ri.httpMethod)
        of ckJson:
            await hc.request(ri.url, ri.httpMethod, $ri.content.j)
        of ckMultiPart:
            await hc.request(ri.url, ri.httpMethod, multipart = ri.content.m)
