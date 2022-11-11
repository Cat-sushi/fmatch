# FMatch

## Description

Fuzzy text matching engine for entity or person screening against denial lists such as BIS Entity List.

## Features

This is just a text matching engine, not a screening engine against denial lists.
You might have to join other propertins of denial lists for practical applications.

- Fuzzy term matching with Levenstein distance and fuzzy query matching
- Provide perfect matching mode to deactivate fuzzy matching
- Respects term importance of IDF
- Canonicalizes expression variants of legal entity types such as **Limited** and **Ltd.**
- Accepts Latin characters, Chinse characters, Katakana characters, and others
- Canonicalizes traditioanal and simplified Chinese characters, and others
- The local web server accepts solo query and parallized bulk queries
- Provide the results cache for performance
- Provide the white queries to avoid screening your company itself

## Usage

### Fetch the public denial lists

```text
dart bin/fetch_public_lists.dart 
```

This fetches lists from [US Consolidated Screening List](https://www.trade.gov/consolidated-screening-list "Consolidated Screening List") and [Japanese METI Foreign Users List](https://www.meti.go.jp/policy/anpo/law05.html#user-list "安全保障貿易管理**Export Control*関係法令：申請、相談に関する通達").

### Compile the web server

```text
dart compile exe -v bin/wserver.dart -o bin/wserver
```

**Note**: The JIT mode doesn't work for some reasons.

### Start the web server

```text
bin/wserver
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

Do not forget to percent encode the query.

### Perfect matching

```text
$ http -b --unsorted ':4049?q="abc"'
{
    "serverId": 1,
    "start": "2022-11-11T00:39:16.506794Z",
    "durationInMilliseconds": 2,
    "inputString": "\"abc\"",
    "rawQuery": "ABC",
    "cachedResult": {
        "cachedQuery": {
            "letType": "na",
            "terms": [
                "ABC"
            ],
            "perfectMatching": true
        },
        "queryScore": 1.0,
        "queryFallenBack": false,
        "matchedEntiries": [
            {
                "entry": "ABC LLC",
                "score": 1.0
            }
        ]
    },
    "message": "Cached result"
}
```

### Send queries and receive results

```text
$ http -b --unsorted :4049 'Content-type:application/json; charset=utf-8' '[]=abc' '[]="def"'
[
    {
        "serverId": 2,
        "start": "2022-11-11T00:40:34.971122Z",
        "durationInMilliseconds": 2,
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
        "serverId": 0,
        "start": "2022-11-11T00:40:34.970496Z",
        "durationInMilliseconds": 2,
        "inputString": "\"def\"",
        "rawQuery": "DEF",
        "cachedResult": {
            "cachedQuery": {
                "letType": "na",
                "terms": [
                    "DEF"
                ],
                "perfectMatching": true
            },
            "queryScore": 1.0,
            "queryFallenBack": false,
            "matchedEntiries": [
                {
                    "entry": "SAZEMANE SANAYE DEF",
                    "score": 1.0
                }
            ]
        },
        "message": ""
    }
]
```

### Run batch queries

```text
$ dart bin/batchwb.dart -i queries.csv
 ...
$ ls
queries.csv
queries_results.csv
```

### Reflesh the server

```text
http :4049/restart
```

This make the server reload the database, reread configurations and settings, and purge the result chache.

### Normalize text as a join key with other properties of the denial lists

```text
$ http -b ':4049/normalize?q=abc'
"ABC"
```

## License

Published under AGPL-3.0 or later. See the LICENSE file.

If you need another different license, contact me.
