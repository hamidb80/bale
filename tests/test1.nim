import std/[unittest, asyncdispatch, options, json]
import bale


const token = staticRead "../bot.token"
let
  bot = newBaleBot token
  updates = waitFor bot.getUpdates(offset = -2)

for u in updates:
  if u.msg.isSome:
    let chid = u.msg.get.chat.id

    echo u.msg.get.JsonNode.pretty
    echo u.msg.get.chat.typ
    echo u.msg.get.frm.username

    waitFor bot.deletemessage(chid, u.msg.get.id)
    let 
      m = waitFor bot.sendPhoto(chid, "cap", "play.png", true)
      m2 = waitFor bot.sendMessage(chid, "wow")
      e = waitFor bot.editMessageText(chid, m2.id, "wow2")
      c = waitFor bot.sendContact(chid, "09140026206", "Iran Nim")
      l = waitFor bot.sendLocation(chid, 0.0, 10.1)
    break
