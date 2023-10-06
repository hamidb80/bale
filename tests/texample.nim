## says hello to anyone sends something

import std/[options, httpclient]
import bale
import bale/helper/stdhttpclient



const
    token = staticRead "../bot.token"
    api = baleBotBaseApi token

let hc = newHttpClient()


proc main =
    var skip = -1

    while true:
        let updates = \hc.req api.getUpdates(offset = skip)
        echo (updates.len, skip)

        for u in updates:
            skip = u.id + 1
            if u.msg.isSome:
                let
                    msg = u.msg.get
                    chid = msg.chat.id

                discard hc.req api.sendMessage(chid, msg.text.get)


when isMainModule:
    main()
