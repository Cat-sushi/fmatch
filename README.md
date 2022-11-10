# FMatch

## Description

Fuzzy text matcher for entity or persn screening against denial lists such as BIS Entity List.

## Features

This is just a text matching engine, but a screening engine against denial lists.
You might have to join other propertins of denial lists for practical applications.

- Fuzzy term matching and fuzzy query matching
- Respect term importance of IDF
- Support Latin characters, Chinse characters, Katakana characters, and others
- Canonicalize traditioanal and simplified Chinese characters, and others
- Support solo query and parallized bulk queries

## Usage

### Fetch the public denial lists

```text
$ dart bin/fetch_public_lists.dart 
```

### Compile the web server

```text
$ dart compile exe -v bin/wserver.dart -o bin/wserver
```

**Note**: JIT mode doesn't work for some reasons.

### Start the web server

```text
$ bin/wserver
```

### Send a query and receive a result

```text
$ http -b --unsorted ':4049?q=abc'
{
    "serverId": 2,
    "start": "2022-11-10T12:21:22.736901Z",
    "durationInMilliseconds": 16,
    "inputString": "abc",
    "rawQuery": "ABC",
    "cachedResult": {
        "cachedQuery": {
            "letType": "na",
            "terms": [
                "ABC"
            ],
            "perfectMatching": false
        },
        "queryScore": 0.8325604366063432,
        "queryFallenBack": false,
        "matchedEntiries": [
            {
                "entry": "ABC LLC",
                "score": 0.8325604366063432
            },
            {
                "entry": "ABMC THAI SOUTH SUDAN CONSTRUCTION",
                "score": 0.6244203274547574
            },
            {
                "entry": "ABMC THAI-SOUTH SUDAN CONSTRUCTION COMPANY LIMITED",
                "score": 0.6244203274547574
            }
        ]
    },
    "message": ""
}
```

### Send queries and receive results

```text
$ http -b --unsorted :4049 'Content-type:application/json; charset=utf-8' '[]=abc' '[]=def'
[
    {
        "serverId": 1,
        "start": "2022-11-10T12:32:38.220773Z",
        "durationInMilliseconds": 0,
        "inputString": "abc",
        "rawQuery": "ABC",
        "cachedResult": {
            "cachedQuery": {
                "letType": "na",
                "terms": [
                    "ABC"
                ],
                "perfectMatching": false
            },
            "queryScore": 0.8325604366063432,
            "queryFallenBack": false,
            "matchedEntiries": [
                {
                    "entry": "ABC LLC",
                    "score": 0.8325604366063432
                },
                {
                    "entry": "ABMC THAI SOUTH SUDAN CONSTRUCTION",
                    "score": 0.6244203274547574
                },
                {
                    "entry": "ABMC THAI-SOUTH SUDAN CONSTRUCTION COMPANY LIMITED",
                    "score": 0.6244203274547574
                }
            ]
        },
        "message": "Cached result"
    },
    {
        "serverId": 2,
        "start": "2022-11-10T12:32:38.220757Z",
        "durationInMilliseconds": 0,
        "inputString": "def",
        "rawQuery": "DEF",
        "cachedResult": {
            "cachedQuery": {
                "letType": "na",
                "terms": [
                    "DEF"
                ],
                "perfectMatching": false
            },
            "queryScore": 0.7244013612530856,
            "queryFallenBack": false,
            "matchedEntiries": [
                {
                    "entry": "SAZEMANE SANAYE DEF",
                    "score": 0.7244013612530856
                },
                {
                    "entry": "VEZARATE DEFA",
                    "score": 0.5433010209398142
                },
                {
                    "entry": "DEIF, MUHAMMED",
                    "score": 0.5433010209398142
                },
                {
                    "entry": "SASEMAN SANAJE DEFA",
                    "score": 0.5433010209398142
                },
                {
                    "entry": "SAZEMANE SANAYE DEFA",
                    "score": 0.5433010209398142
                },
                {
                    "entry": "VEZARAT-E DEFA VA POSHTYBANI-E NIRU-HAYE MOSALLAH",
                    "score": 0.5433010209398142
                }
            ]
        },
        "message": "Cached result"
    }
]
```

### Reflesh the server

```text
http :4049/restart
```

### Normalize text for join key with other properties of denial lists

```text
$ http -b ':4049/normalize?q=abc'
"ABC"
```

## License

Published under AGPL-3.0 or later. See the LICENSE file.

If you want another license, contact me.