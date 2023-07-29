## Bale Bot API v1.0
## https://dev.bale.ai/api

import std/[asyncdispatch, httpclient, uri]
import std/[json, options, strutils]
import bale/private/utils

# ------ types -----------------------------------

type
  UriQuery = tuple[key: string, value: string]
  Array[T] = seq[T]

  BaleBot = object
    apiRoot: Uri
    lastUpdateId: int

  BaleError = ref object of CatchableError
    code: int
    # msg: string (description) - inherits this field

  BaleResult* = distinct JsonNode
  BaleIntResult* = distinct BaleResult
  BaleBoolResult* = distinct BaleResult
  GetUpdatesResult* = distinct BaleResult
  GetFileResult* = distinct BaleResult
  BaleMessageResult* = distinct BaleResult
  GetChatAdministratorsResult* = distinct BaleResult
  GetChatResult* = distinct BaleResult
  GetUserResult* = distinct BaleResult
  GetChatMemberResult* = distinct BaleResult

  BaleObject* = distinct JsonNode
  Update* = distinct BaleObject
  User* = distinct BaleObject
  MessageEntity* = distinct BaleObject
  BFile* = distinct BaleObject
  Chat* = distinct BaleObject
  Invoice* = distinct BaleObject
  ChatMember* = distinct BaleObject
  Audio* = distinct BaleObject
  Document* = distinct BaleObject
  PhotoSize* = distinct BaleObject
  Video* = distinct BaleObject
  Voice* = distinct BaleObject
  Contact* = distinct BaleObject
  Location* = distinct BaleObject
  Message* = distinct BaleObject
  CallbackQuery* = distinct BaleObject
  ShippingQuery* = distinct BaleObject
  OrderInfo* = distinct BaleObject
  ShippingAddress* = distinct BaleObject
  PreCheckoutQuery* = distinct BaleObject
  SuccessfulPayment* = distinct BaleObject

  ReplyKeyboardMarkup* = distinct BaleObject

  ChatTypes* = enum
    ctPrivate = "private"
    ctGroup = "group"
    ctSuperGroup = "supergroup"
    ctChannel = "channel"

  UserChatStatus* = enum
    ucsCreator = "creator"
    ucsAdministrator = "administrator"
    ucsMember = "member"
    ucsRestricted = "restricted"
    ucsLeft = "left"
    ucsKicked = "kicked"

  MessageEntityKind = enum
    mekMention = "mention"
    mekHashtag = "hashtag"
    mekBotCommand = "bot_command"
    mekUrl = "url"
    mekEmail = "email"
    mekBold = "bold"
    mekItalic = "italic"
    mekCode = "code"
    mekPre = "pre"
    mekTextLink = "text_link"
    mekTextMention = "text_mention"


defFields Update, {
  (update_id, id): int,
  (message, msg): Option[Message],
  (edited_message, edited_msg): Option[Message],
  (channel_post, channp): Option[Message],
  (edited_channel_post, edited_channp): Option[Message],
  (callback_query, cbq): Option[CallbackQuery],
  (shipping_query, shq): Option[ShippingQuery],
  (pre_checkout_query, pckq): Option[PreCheckoutQuery]}

defFields User, {
  id: int,
  username: string,
  first_name: string,
  last_name: string,
  language_code: Option[string],
  is_bot: bool}

defFields Message, {
  (message_id, id): int,
  (`from`, frm): User,
  date: int,
  chat: Chat,
  text: Option[string],
  forwarded_from: Option[User],
  forwarded_from_chat: Option[Chat],
  forwarded_from_message_id: Option[int],
  forwarded_date: Option[int],
  reply_to: Option[Message],
  edit_date: Option[int],
  entities: Option[Array[MessageEntity]],
  caption_entities: Option[Array[MessageEntity]],
  audio: Option[Audio],
  document: Option[Document],
  photo: Option[Array[PhotoSize]],
  video: Option[Video],
  voice: Option[Voice],
  caption: Option[string],
  contact: Option[Contact],
  location: Option[Location],
  new_chat_members: Option[Array[User]],
  left_chat_memeber: Option[User],
  new_chat_title: Option[string],
  new_chat_photo: Option[Array[PhotoSize]],
  delete_chat_photo: Option[bool],
  group_chat_created: Option[bool],
  supergroup_chat_created: Option[bool],
  channel_chat_created: Option[bool],
  pinned_message: Option[Message],
  invoice: Option[Invoice],
  successful_payment: Option[SuccessfulPayment],
  edited_message: Option[Message],
  channel_post: Option[Message],
  edited_channel_post: Option[Message],
  callback_query: Option[CallbackQuery],
  shipping_query: Option[ShippingQuery],
  pre_checkout_query: Option[PreCheckoutQuery]}

defFields Chat, {
  id: int,
  (`type`, typ): Enum[ChatTypes],
  title: string,
  username: string,
  first_name: string,
  last_name: string,
  all_members_are_administrators: bool,
  description: string,
  invite_link: string,
  pinned_message: Option[Message],
  sticker_set_name: string,
  can_set_sticker_set: bool}

defFields ChatMember, {
  user: User,
  status: Enum[UserChatStatus],
  until_date: int,
  can_be_edited: bool,
  can_change_info: bool,
  can_post_messages: bool,
  can_edit_messages: bool,
  can_delete_messages: bool,
  can_invite_users: bool,
  can_restrict_members: bool,
  can_pin_messages: bool,
  can_promote_members: bool,
  can_send_messages: bool,
  can_send_media_messages: bool,
  can_send_other_messages: bool,
  can_add_web_page_previews: bool}

defFields BFile, {
  (file_id, id): string,
  (file_size, size): int,
  (file_path, path): string}

defFields PhotoSize, {
  file_id: string,
  width: int,
  height: int,
  file_size: int}

defFields Video, {
  file_id: string,
  width: int,
  height: int,
  duration: int,
  thumb: PhotoSize,
  mime_type: string,
  file_size: int}

defFields Voice, {
  file_id: string,
  duration: int,
  mime_type: string,
  file_size: int}

defFields Contact, {
  phone_number: string,
  first_name: string,
  last_name: string,
  user_id: int}

defFields Location, {
  longitude: float,
  latitude: float}

defFields SuccessfulPayment, {
  currency: string,
  total_amount: int,
  invoice_payload: string,
  shipping_option_id: string,
  order_info: OrderInfo,
  telegram_payment_charge_id: string,
  provider_payment_charge_id: string}

defFields OrderInfo, {
  name: string,
  phone_number: string,
  email: string,
  shipping_address: ShippingAddress,
  telegram_payment_charge_id: string,
  provider_payment_charge_id: string}

defFields ShippingAddress, {
  country_code: string,
  stat: string,
  city: string,
  street_line1: string,
  street_line2: string,
  post_cod: string}

defFields Invoice, {
  title: string,
  description: string,
  start_parameter: string,
  currency: string,
  total_amount: int}

defFields MessageEntity, {
  (`type`, typ): Enum[MessageEntityKind],
  offset: int,
  length: int,
  url: string,
  user: User}

defFields CallbackQuery, {
  id: string,
  (`from`, frm): User,
  (message, msg): Message,
  (inline_message_id, imsgid): string,
  (chat_instance, chati): string,
  data: string,
  (game_short_name, gname): string}

defFields ShippingQuery, {
  id: string,
  (`from`, frm): User,
  invoice_payload: string,
  shipping_address: ShippingAddress}

defFields PreCheckoutQuery, {
  id: string,
  (`from`, frm): User,
  currency: string,
  total_amount: int,
  invoice_payload: string,
  shipping_option_id: string,
  order_info: OrderInfo}


template defResultType(ObjName, ResultType): untyped {.dirty.} =
  defFields ObjName, {
    (result, res): ResultType,
    error_code: Option[int],
    ok: bool,
    description: string}

defResultType BaleBoolResult, bool
defResultType BaleIntResult, int
defResultType BaleMessageResult, Message
defResultType GetUpdatesResult, Array[Update]
defResultType GetFileResult, BFile
defResultType GetChatAdministratorsResult, Array[ChatMember]
defResultType GetUserResult, User
defResultType GetChatResult, Chat
defResultType GetChatMemberResult, ChatMember

# ------ init -----------------------------------

proc newBaleBot*(token: string): BaleBot =
  BaleBot(
    apiRoot: parseUri "https://tapi.bale.ai/bot" & token,
    lastUpdateId: -1)

# ------ utils -----------------------------------

func initQuery: seq[UriQuery] = @[]
const noQuery = initQuery()

template newBaleError(ecode, desc): untyped =
  let err = new BaleError
  err.code = ecode
  err.msg = desc
  err

template assertOkRaw(res): untyped =
  if not res.ok:
    raise newBaleError(res.error_code.get 0, res.description)

template assertOkTemp(resp): untyped =
  let r = resp
  assertOkRaw r

template assertOkSelf(resp): untyped =
  let r = resp
  assertOkRaw r
  r.result()

# ------ messages -----------------------------------

proc sendMessage*(b: BaleBot,
  chat_id: int,
  text: string,
  reply_markup: Option[ReplyKeyboardMarkup] = none ReplyKeyboardMarkup,
  reply_to_message_id: int = -1,
  ): Future[Message] {.addProcName, queryFields, async.} =

  # if reply_markup.isSome:
  #   payload["reply_markup"] = %reply_markup.get

  # if reply_to_message_id != -1:
  #   payload["reply_to_message_id"] = %reply_to_message_id

  return assertOkSelf BaleMessageResult postc toJson {chat_id, text,
      ?reply_to_message_id}

proc editMessageText*(b: BaleBot,
  chat_id, message_id: int,
  text: string,
  reply_markup: Option[ReplyKeyboardMarkup] = none ReplyKeyboardMarkup,
  ): Future[Message] {.addProcName, async.} =
  # if reply_markup.isSome:
  #   payload["reply_markup"] = %reply_markup.get

  return assertOkSelf BaleMessageResult postc toJson {chat_id, message_id, text}

proc deleteMessage*(b: BaleBot, chat_id, message_id: int) {.addProcName, async.} =
  assertOkTemp BaleBoolResult getc toQuery {chat_id, message_id}

# ------ updates -----------------------------------

proc setWebhook*(b: BaleBot, url: string) {.addProcName, async.} =
  assertOkTemp BaleBoolResult postc url

proc deleteWebhook*(b: BaleBot) {.addProcName, async.} =
  assertOkTemp BaleBoolResult getc noQuery

proc getUpdates*(b: BaleBot, offset, limit: int = -1):
  Future[seq[Update]] {.addProcName, queryFields, async.} =
  return assertOkSelf GetUpdatesResult getc toQuery {?offset, ?limit}

# ------ users -----------------------------------

proc getMe*(b: BaleBot): Future[User] {.addProcName, async.} =
  return assertOkSelf GetUserResult getc noQuery

# ------ attachments -----------------------------------

proc sendPhoto*(b: BaleBot,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  var m = newMultipartData toQuery {chat_id, caption, ?reply_to_message_id}
  m.addCustomFile "photo", file, is_binary
  return assertOkSelf BaleMessageResult postc m

proc sendAudio*(b: BaleBot,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  duration: int = -1,
  title: string = "",
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  var m = newMultipartData toQuery {chat_id, caption,
    ?duration, ?title, ?reply_to_message_id}
  m.addCustomFile "audio", file, is_binary
  return assertOkSelf BaleMessageResult postc m

proc sendDocument*(b: BaleBot,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  var m = newMultipartData toQuery {chat_id, caption, ?reply_to_message_id}
  m.addCustomFile "document", file, is_binary
  return assertOkSelf BaleMessageResult postc m

proc sendVideo*(b: BaleBot,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  duration: int = -1,
  width: int = -1,
  height: int = -1,
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  var m = newMultipartData toQuery {chat_id, caption,
    ?duration, ?width, ?height, ?reply_to_message_id}
  m.addCustomFile "video", file, is_binary
  return assertOkSelf BaleMessageResult postc m

proc sendVoice*(b: BaleBot,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  duration: int = -1,
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  var m = newMultipartData toQuery {chat_id, caption,
    ?duration, ?reply_to_message_id}
  m.addCustomFile "voice", file, is_binary
  return assertOkSelf BaleMessageResult postc m

proc sendLocation*(b: BaleBot,
  chat_id: int,
  latitude, longitude: float,
  caption: string = "",
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  return assertOkSelf BaleMessageResult postc toJson {
      chat_id, latitude, longitude, caption, ?reply_to_message_id}

proc sendContact*(b: BaleBot,
  chat_id: int,
  phone_number: string,
  first_name: string,
  last_name: string = "",
  reply_to_message_id: int = -1
  ): Future[Message] {.addProcName, queryFields, async.} =
  return assertOkSelf BaleMessageResult postc toJson {
    chat_id, phone_number, first_name, ?last_name, ?reply_to_message_id}

proc getFile*(b: BaleBot, fileId: string):
  Future[BFile] {.addProcName, async.} =
  return assertOkSelf GetFileResult getc toQuery {file_id}

# ------ chat -----------------------------------

proc getChat*(b: BaleBot, chat_id: int):
  Future[Chat] {.addProcName, async.} =
  return assertOkSelf GetChatResult getc toQuery {chat_id}

proc getChatAdministrators*(b: BaleBot, chat_id: int):
  Future[seq[ChatMember]] {.addProcName, async.} =
  return assertOkSelf GetChatAdministratorsResult getc toQuery {chat_id}

proc getChatMembersCount*(b: BaleBot, chat_id: int):
  Future[int] {.addProcName, async.} =
  return assertOkSelf BaleIntResult getc toQuery {chat_id}

proc getChatMember*(b: BaleBot, chat_id, user_id: int):
  Future[ChatMember] {.addProcName, async.} =
  return assertOkSelf GetChatMemberResult getc toQuery {chat_id, user_id}

# ------ payments -----------------------------------

# proc sendInvoice*(b: BaleBot,
#   chat_id: int,
#   title, description, provider_token, start_parameter, currency: string,
#   prices: seq[],
#   payload, provider_data: string =  "",
#   provider_data, photo_url: string = "",
#   photo_size: int,
#   photo_width: int,
#   photo_height: int,
#   need_name: bool,
#   need_phone_number: bool,
#   need_email: bool,
#   need_shipping_address: bool,
#   is_flexible: bool,
#   disable_notification: bool,
#   reply_markup: ReplyKeyboardMarkup,
#   reply_to_message_id: int = -1
# ): Future[Message] {.addProcName, queryFields, async.} =
#   return assertOkSelf BaleMessageResult postc newMultipartData toQuery {
#     chat_id, phone_number, first_name, ?last_name, ?reply_to_message_id}
