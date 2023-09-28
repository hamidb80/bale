import std/[unittest, asyncdispatch, options, json, os, random]
import bale

randomize()

const token = staticRead "../bot.token"
let
  bot = newBaleBot token
  updates = waitFor bot.getUpdates(offset = -2)

for u in updates:
  if u.msg.isSome:
    let
      msg = u.msg.get
      chid = msg.chat.id

    echo msg.JsonNode.pretty
    echo msg.chat.typ
    echo msg.frm.username

    let
      n = rand 1..10
      ph = waitFor bot.sendMessage(chid, "first")
      # ph = waitFor bot.sendPhoto(chid, "cap", "play.png", true)
      m = waitFor bot.sendMessage(chid, "wow",
        reply_markup = some ReplyKeyboardMarkup(
        keyboard: some @[@[
          KeyboardButton(text: "up" & $n),
          KeyboardButton(text: "down" & $n),
        ]],
        one_time_keyboard: true,
      ), reply_to_message_id = ph.id)
      # e = waitFor bot.editMessageText(chid, m.id, "wow edited")
      c = waitFor bot.sendContact(chid, "09557726286", "Iran Nim")
      k = waitFor bot.sendMessage(chid, "wow",
        reply_markup = some ReplyKeyboardMarkup(
        inline_keyboard: some @[@[
          InlineKeyboardButton(text: "<<", callback_data: "prev"),
          InlineKeyboardButton(text: ">>", callback_data: "next"),
        ]],
      ), reply_to_message_id = ph.id)
      r = waitFor bot.sendMessage(chid, "remove keyboard",
        reply_markup = some ReplyKeyboardMarkup(keyboard: some default seq[seq[
            KeyboardButton]]))

      # XXX l = waitFor bot.sendLocation(chid, 0.0, 10.1)

    waitFor bot.deletemessage(chid, c.id)
    break
