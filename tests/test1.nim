import std/[unittest, asyncdispatch, options, json]
import bale


const token = staticRead "../bot.token"
let
  bot = newBaleBot token
  updates = waitFor bot.getUpdates(offset = -2)

for u in updates:
  if u.msg.isSome:
    let
      msg =  u.msg.get
      chid = msg.chat.id

    echo msg.JsonNode.pretty
    echo msg.chat.typ
    echo msg.frm.username

    let 
      ph = waitFor bot.sendPhoto(chid, "cap", "play.png", true)
      m = waitFor bot.sendMessage(chid, "wow", reply_to_message_id = ph.id)
      e = waitFor bot.editMessageText(chid, m.id, "wow edited")
      c = waitFor bot.sendContact(chid, "09140026206", "Iran Nim")
      # XXX l = waitFor bot.sendLocation(chid, 0.0, 10.1) 

    waitFor bot.deletemessage(chid, c.id)
    break
