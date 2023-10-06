import std/[options, json,random, httpclient]
import bale, bale/helper/stdhttpclient

randomize()

const token = staticRead "../bot.token"
let
  api = baleApiRoot token
  hc = newHttpClient()
  updates = hc.req api.getUpdates(offset = -2)

for u in \updates:
  if u.msg.isSome:
    let
      msg = u.msg.get
      chid = msg.chat.id

    echo msg.JsonNode.pretty
    echo msg.chat.typ
    echo msg.frm.username

    let
      n = rand 1..10
      ph = hc.req api.sendMessage(chid, "first")
      # ph = bot.sendPhoto(chid, "cap", "play.png", true)
      phid = (\ph).id
      m = hc.req api.sendMessage(chid, "wow",
        reply_markup = some ReplyKeyboardMarkup(
        keyboard: some @[@[
          KeyboardButton(text: "up" & $n),
          KeyboardButton(text: "down" & $n),
        ]],
        one_time_keyboard: true,
      ), reply_to_message_id = phid)
      e = hc.req api.editMessageText(chid, (\m).id, "wow edited")
      c = hc.req api.sendContact(chid, "09557726286", "Iran Nim")
      cid = (\c).id
      k = hc.req api.sendMessage(chid, "wow",
        reply_markup = some ReplyKeyboardMarkup(
        inline_keyboard: some @[@[
          InlineKeyboardButton(text: "<<", callback_data: "prev"),
          InlineKeyboardButton(text: ">>", callback_data: "next"),
        ]],
      ), reply_to_message_id = phid)
      r = hc.req sendMessage(api, chid, "remove keyboard",
        reply_markup = some ReplyKeyboardMarkup(keyboard: some default seq[seq[
            KeyboardButton]]))

      l = hc.req api.sendLocation(chid, 0.0, 10.1)
      d = hc.req api.deletemessage(chid, cid)

    break
