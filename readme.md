# [Bale Bot](https://dev.bale.ai/api/) Api Client in Nim 👑

## Features
+ ***fast***: No mapping or intermidiate representation, just stores `JsonNode`s as `distinct` ones.
+ ***free***: just define `req` procedure and use it with any HTTP library that you want. see `src/bale/helper/stdhttpclient.nim`
+ ***safe***: compile time checks & Auto-completes!! 
+ ***extensible***: The docs updated or I missed some APIs/fields? No problem! just add your own function becuase it's all `JsonNode`s and functions!
+ ***easy to write***: There are some alises for fields like `message` as `msg` or `id` instead of `update_id` field for `Update` object!

## How to Use
See `tests/` at the moment

## Docs
Docs? Really? Just take a look at `src/bale.nim`! It's just one file man!
