import std/[httpclient, json]
import bale
import bale/helper/stdhttpclient

const token = staticRead "../bot.token"

var hc1 = newHttpClient()
echo JsonNode hc1.req getUpdates baleBotBaseApi token

import std/asyncdispatch
var hc2 = newAsyncHttpClient()
echo JsonNode waitfor hc2.req getUpdates baleBotBaseApi token
