import std/[unittest, asyncdispatch, options, json]
import bale

const token = staticRead "../bot.token"
let
  bot = newBaleBot token
  updates = waitFor bot.getUpdates

for u in updates.result:
  if u.msg.isSome:
    echo u.msg.get.JsonNode.pretty
    echo u.msg.get.chat.typ
    echo u.msg.get.frm.username
