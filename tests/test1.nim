import std/[unittest, asyncdispatch, options, json]
import bale
import os

const token = staticRead "../bot.token"
let
  bot = newBaleBot token
  updates = waitFor bot.getUpdates()

for u in updates:
  if u.msg.isSome:
    echo u.msg.get.JsonNode.pretty
    echo u.msg.get.chat.typ
    echo u.msg.get.frm.username
    # echo u.msg.get.forwarded_from
    # waitFor bot.deletemessage(u.msg.get.chat.id, u.msg.get.id)

    let m = waitFor bot.sendPhoto(
      u.msg.get.chat.id,
      "dsa",
      "https://5.imimg.com/data5/OF/GC/MY-4584302/red-rose-flower-500x500.jpg",
      false,
      )

    # let m = waitFor bot.sendMessage(
    #   u.msg.get.chat.id, "wow")

    # let e = waitFor bot.editMessageText(
    #   u.msg.get.chat.id, m.id ,"wow2")

    # echo e.JsonNode.pretty
