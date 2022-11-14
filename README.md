# FMatch

## Description

Fuzzy text matching engine for entity screening or person screening against denial lists such as BIS Entity List.

Actutually, this is just a text matching engine, but not a screening system against denial lists.
You might have to join results with denial lists for practical applications.
This is intended to be a subsystem with local web API or dart API.

## Features

- Fuzzy term matching using Levenshtein distance.
- Divided query terms matching with single list term.
- Fuzzy query matching respecting term similarity, term order, and term importance of IDF.
- Perfect matching mode deactivating fuzzy matchings for reducing false positives in some cases.
- Accepting Latin characters, Chinese characters, Katakana characters, and others.
- Canonicalaization of traditioanal and simplified Chinese characters, and others.<br>
This makes matching insensitive to character simplification.
- Canonicalaization of spelling variants of legal entity types such as "Limitd" and "Ltd.".<br>
This makes matching insensitive to spelling variants of legal entity types.
- White queries for avoiding screening your company itself and consequent false positives.
- Results cache for time performance.
- Solo query accepted by the web server for interactive UIs.
- Bulk queries accepted and processed parallel by the web server for batch applicaions.
- Text normalizing API for outer larger systems joining results with the denial lists.
- And others.

## Usage

### Fetch the public denial lists (optional)

```text
dart bin/fetch_public_lists.dart 
```

This fetches lists from [US Government's Consolidated Screening List](https://www.trade.gov/consolidated-screening-list "Consolidated Screening List") and [Japanese METI Foreign Users List](https://www.meti.go.jp/policy/anpo/law05.html#user-list "安全保障貿易管理**Export Control*関係法令：申請、相談に関する通達").

### Compile the local web server

```text
dart compile exe -v bin/wserver.dart -o bin/wserver
```

**Note**: The JIT mode doesn't work for some reasons. See dart-lang/sdk#50082.

### Start the local web server

```text
bin/wserver
```

### Send a query and receive the result

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

Do not forget to percent-encode the query.

### Perfect matching

Enclose the whole query with double quates.

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

### Post queries in JSON and receive the results

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

### Run the sample batch

```text
$ ls batch
queries.csv
$ dart bin/batchwb.dart -i batch/queries.csv
 ...
$ ls batch
queries.csv
queries_results.csv
```

### Reflesh the server

```text
http :4049/restart
```

This makes the server reload the database, reread the configurations and the settings, and purge the result chache.
This is useful when the denial lists are updated or the configurations/ settings are modified.

### Get normalized text as a key of join with the denial lists

```text
$ http -b ':4049/normalize?q=abc'
"ABC"
```

This is useful for prepareing outer larger systems which join results with  the denial lists.

Note that results from this subsystem are normalized in the same way.

## License

Published under AGPL-3.0 or later. See the LICENSE file.

If you need another different license, contact me.
