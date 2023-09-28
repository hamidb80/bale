## says hello to anyone sends something

import std/[asyncdispatch, options, os]
import bale


let
    token = getEnv "BALE_BOT_TOKEN"
    bot = newBaleBot token

template forever(body): untyped =
    while true:
        body

proc main =
    var skip = -1

    forever:
        try:
            let updates = waitFor bot.getUpdates(offset = skip+1)
            echo (updates.len, skip)

            for u in updates:
                skip = u.id
                if u.msg.isSome:
                    let
                        msg = u.msg.get
                        chid = msg.chat.id

                    discard waitFor bot.sendMessage(chid, "heelo")

        except:
            echo "temp error"


when isMainModule: 
    main()
