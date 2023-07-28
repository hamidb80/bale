import std/[unittest, asyncdispatch, options, json]
import bale

const token = staticRead "../bot.token"
let
  bot = newBaleBot token
  updates = waitFor bot.getUpdates()

for u in updates:
  if u.msg.isSome:
    echo u.msg.get.JsonNode.pretty
    echo u.msg.get.chat.typ
    echo u.msg.get.frm.username
    # waitFor bot.deletemessage(u.msg.get.chat.id, u.msg.get.id)

# echo "-------------------"

let me = bot.getMe.waitFor
echo me.JsonNode.pretty
echo me.language_code