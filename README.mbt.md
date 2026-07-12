# MoonBit JSONPath

[![MoonBit](https://img.shields.io/badge/MoonBit-2026-blue)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache--2.0-green)](LICENSE)

MoonBit JSONPath is a small JSONPath parser and evaluator written in MoonBit. It targets the core query patterns described by [RFC 9535](https://www.rfc-editor.org/rfc/rfc9535) and integrates directly with `moonbitlang/core/json`.

The project is maintained for the MoonBit Open Source Ecosystem Competition 2026. The public repositories are:

- GitHub: <https://github.com/ppyj663/moon-jsonpath>
- GitLink: <https://gitlink.org.cn/ppyj663/moon-jsonpath>

## Features

- Parses JSONPath strings into a compact MoonBit AST.
- Evaluates queries against `Json` values from `moonbitlang/core/json`.
- Supports root, child, bracket child, recursive descendant, wildcard, array index, negative index, slicing, union, and filter selectors.
- Supports escape sequences and unicode escapes in bracket name selectors.
- Ships focused unit tests and a runnable CLI example.
- Uses the Apache-2.0 license.

## Installation

The module name is:

```bash
ppyj663/moon-jsonpath
```

Install the published Mooncakes package from your project root:

```bash
moon add ppyj663/moon-jsonpath
```

Then import it from a package:

```mbt nocheck
import {
  "ppyj663/moon-jsonpath" @jsonpath,
}
```

## Quick Start

```mbt nocheck
let json = @json.parse(
  #|{
  #|  "store": {
  #|    "book": [
  #|      { "title": "Sayings of the Century", "price": 8.95 },
  #|      { "title": "Sword of Honour", "price": 12.99 }
  #|    ]
  #|  }
  #|}
)

match @jsonpath.query(json, "$.store.book[0].title") {
  Ok(values) => println(values[0].stringify())
  Err(message) => println("query failed: \{message}")
}
```

Run the included example:

```bash
moon run cmd/main
```

Expected output:

```text
query: $.store.book[0].title
matches: 1
"Sayings of the Century"
```

## Supported Syntax

| Syntax | Meaning | Example |
| --- | --- | --- |
| `$` | Root node | `$` |
| `.<name>` | Object child selector | `$.store.bicycle` |
| `['<name>']` or `["<name>"]` | Bracket child selector (supports string escapes) | `$['store']['book']` |
| `.. <name>` without the space | Recursive descendant selector | `$..price` |
| `.*` / `[*]` | Object or array wildcard | `$.store.book[*]` |
| `[<number>]` | Array index (supports negative indices) | `$.store.book[-1]` |
| `[<start>:<end>:<step>]` | Array slicing (supports positive and negative steps) | `$.store.book[1:3]` |
| `[<sel1>, <sel2>]` | Union selector | `$.store.book[0, 2]` |
| `[?(<expr>)]` | Filter selector (supports comparisons, logical AND/OR/NOT) | `$.store.book[?(@.price < 10)]` |

Not yet supported: function extensions.

## API

```mbt nocheck
pub fn parse(input : String) -> Result[JSONPath, String]
pub fn evaluate(json : Json, path : JSONPath) -> Array[Json]
pub fn query(json : Json, path_str : String) -> Result[Array[Json], String]
```

`query` is the usual entry point. It returns `Err(message)` for unsupported or malformed JSONPath syntax and returns an empty array when a valid query simply finds no matching node.

## Development

```bash
moon update
moon fmt --check
moon check --deny-warn
moon test
moon run cmd/main
```

The repository also contains a GitHub Actions workflow that runs the same verification path on every push and pull request.

Mooncakes package `ppyj663/moon-jsonpath` version `0.2.0` is published. The release was validated with `moon package`, `moon publish --dry-run`, and `moon publish`.

## Competition Closeout

Closeout evidence is tracked in [docs/competition/acceptance.md](docs/competition/acceptance.md). The one-page project report is [report.pdf](report.pdf).

## License

This project is released under the [Apache License 2.0](LICENSE).
