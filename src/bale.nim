## Bale Bot API v1.0
## https://dev.bale.ai/api
## https://dev.bale.ai/faq

import std/[httpclient]
import std/[json, options, strutils, uri]
import bale/private/[utils, request]

# ------ types -----------------------------------

type
  Array[T] = seq[T]

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

  ReplyKeyboardMarkup* = object
    keyboard*: Option[seq[seq[KeyboardButton]]]
    inline_keyboard*: Option[seq[seq[InlineKeyboardButton]]]
    resize_keyboard*: bool
    one_time_keyboard*: bool
    selective*: bool

  KeyboardButton* = object
    text*: string
    request_contact*: bool
    request_location*: bool

  InlineKeyboardButton* = object
    text*: string
    callback_data*: string


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
  last_name: Option[string],
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
    (result, resp, `\`): ResultType,
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

proc baleBotBaseApi*(token: string): string =
  "https://tapi.bale.ai/bot" & token & "/"

# ------ utils -----------------------------------

func `?`(u: string, q: openArray[(string, string)]): string =
  u & '?' & encodeQuery q


template fn2(typ): untyped =
  proc(body: string): typ =
    typ parseJson body

template URL: untyped {.dirty.} =
  apiRoot & procname


template r(hm, tt, u, c): untyped =
  let con =
    when c is JsonNode: Content(kind: ckJson, j: c)
    elif c is MultiPartData: Content(kind: ckMultiPart, m: c)
    elif c is void: Content(kind: ckNone)
    else: error "invalid type"

  RequestInfo[tt](
    httpMethod: hm,
    url: u,
    content: con,
    responseParser: fn2 tt)


# ------ messages -----------------------------------

proc sendMessage*(
  apiRoot: string,
  chat_id: int,
  text: string,
  reply_markup: Option[ReplyKeyboardMarkup] = none ReplyKeyboardMarkup,
  reply_to_message_id: int = -1,
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL,
    toJson {chat_id, text, ?reply_markup, ?reply_to_message_id})

proc editMessageText*(
  apiRoot: string,
  chat_id,
  message_id: int,
  text: string,
  reply_markup: Option[ReplyKeyboardMarkup] = none ReplyKeyboardMarkup,
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL,
    toJson {chat_id, message_id, text, ?reply_markup})

proc deleteMessage*(
  apiRoot: string,
  chat_id, message_id: int
  ): auto {.addProcName.} =

  r(HttpGet, BaleBoolResult, URL ? (toQuery {chat_id, message_id}), void)

# # ------ updates -----------------------------------

proc setWebhook*(apiRoot, url: string): auto {.addProcName.} =
  r(HttpPost, BaleBoolResult, URL, newMultipartData {"url": url})

proc deleteWebhook*(apiRoot: string): auto {.addProcName.} =
  r(HttpGet, BaleBoolResult, URL, void)

proc getUpdates*(
  apiRoot: string,
  offset, limit: int = -1
  ): auto {.addProcName, defParamDefaults.} =
  r(HttpGet, GetUpdatesResult, URL ? toQuery {?offset, ?limit}, void)

# # ------ users -----------------------------------

proc getMe*(apiRoot: string): auto {.addProcName.} =
  r(HttpGet, GetUserResult, URL, void)

# # ------ attachments -----------------------------------

proc sendPhoto*(
  apiRoot: string,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL, multipartFile({chat_id, caption,
      ?reply_to_message_id}, "photo", file, is_binary))

proc sendAudio*(
  apiRoot: string,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  duration: int = -1,
  title: string = "",
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL, multipartFile({chat_id, caption,
    ?duration, ?title, ?reply_to_message_id}, "audio", file, is_binary))

proc sendDocument*(
  apiRoot: string,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL, multipartFile({
    chat_id, caption, ?reply_to_message_id}, "document", file, is_binary))

proc sendVideo*(
  apiRoot: string,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  duration: int = -1,
  width: int = -1,
  height: int = -1,
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =


  r(HttpPost, BaleMessageResult, URL, multipartFile({chat_id, caption,
    ?duration, ?width, ?height, ?reply_to_message_id}, "video", file, is_binary))

proc sendVoice*(
  apiRoot: string,
  chat_id: int,
  caption: string,
  file: string,
  is_binary: bool,
  duration: int = -1,
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL, multipartFile({chat_id, caption,
    ?duration, ?reply_to_message_id}, "voice", file, is_binary))

proc sendLocation*(
  apiRoot: string,
  chat_id: int,
  latitude, longitude: float,
  caption: string = "",
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL, toJson {
      chat_id, latitude, longitude, ?caption, ?reply_to_message_id})

proc sendContact*(
  apiRoot: string,
  chat_id: int,
  phone_number: string,
  first_name: string,
  last_name: string = "",
  reply_to_message_id: int = -1
  ): auto {.addProcName, defParamDefaults.} =

  r(HttpPost, BaleMessageResult, URL, toJson {
    chat_id, phone_number, first_name, ?last_name, ?reply_to_message_id})

proc getFile*(
  apiRoot: string,
  fileId: string
  ): auto {.addProcName.} =

  r(HttpGet, GetFileResult, URL ? toQuery {file_id}, void)

# # ------ chat -----------------------------------

proc getChat*(
  apiRoot: string,
  chat_id: int
  ): auto {.addProcName.} =

  r(HttpGet, GetChatResult, URL ? toQuery {chat_id}, void)

proc getChatAdministrators*(
  apiRoot: string,
  chat_id: int
  ): auto {.addProcName.} =

  r(HttpGet, GetChatAdministratorsResult, URL ? toQuery {chat_id}, void)

proc getChatMembersCount*(
  apiRoot: string,
  chat_id: int
  ): auto {.addProcName.} =

  r(HttpGet, BaleIntResult, URL ? toQuery {chat_id}, void)

proc getChatMember*(
  apiRoot: string,
  chat_id: int,
  user_id: int
  ): auto {.addProcName.} =

  r(HttpGet, GetChatMemberResult, URL ? toQuery {chat_id}, void)

# ------ payments -----------------------------------

# proc sendInvoice*(
  # apiRoot: string,
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
# ): auto {.addProcName, defParamDefaults.} =
#   BaleMessageResult HttpPost newMultipartData toQuery {
#     chat_id, phone_number, first_name, ?last_name, ?reply_to_message_id}
