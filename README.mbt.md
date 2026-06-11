# MoonBit JSONPath

[![MoonBit Version](https://img.shields.io/badge/MoonBit-2024+-blue.svg)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

这是一个基于 MoonBit 实现的 JSONPath 解析与执行库。项目参考了 [RFC 9535 标准](https://www.rfc-editor.org/rfc/rfc9535) 的核心规范，提供了一套用于从复杂 JSON 结构中查询和提取节点的工具。

## 核心特性

*   **类型安全**：基于 MoonBit 强类型系统，并与官方库的 `@json.Json` 类型深度整合，提供安全的解析和查询能力。
*   **无外部依赖**：项目只使用了 MoonBit 标准库，没有引入第三方包。代码结构简单，可以直接编译到 WebAssembly 环境。
*   **语法支持**：支持点表示法 (`$.store.book`) 和括号表示法 (`$['store']['book']`)，同时也支持深度递归搜索 (`..`)、通配符 (`*`) 和数组索引访问 (`[number]`)。
*   **实现架构**：采用了经典的词法解析 (Parser) -> 抽象语法树 (AST) -> 执行求值 (Evaluator) 的结构分层设计，方便后续维护和功能扩展。

## 安装

可以通过 moon 包管理器添加到你的项目中：

```bash
moon add ppyj663/jsonpath
```

在 `moon.pkg.json` 中配置引入：

```json
{
  "import": [
    "ppyj663/jsonpath"
  ]
}
```

## 快速上手

下面是一个简单的示例，展示如何查询目标字段。

```moonbit
let json_str =
  #|{
  #|  "store": {
  #|    "book": [
  #|      { "category": "reference", "author": "Nigel Rees", "title": "Sayings of the Century", "price": 8.95 },
  #|      { "category": "fiction", "author": "Evelyn Waugh", "title": "Sword of Honour", "price": 12.99 }
  #|    ],
  #|    "bicycle": { "color": "red", "price": 19.95 }
  #|  }
  #|}

// 1. 将字符串解析为 @json.Json 类型
let json = @json.parse!(json_str)

// 2. 使用 JSONPath 查询数据
match @jsonpath.query(json, "$.store.book[0].title") {
  Ok(res) => {
    // res 类型为 Array[Json]
    println("找到 \{res.length()} 个匹配项:")
    println(res[0]) // 输出: Json::String("Sayings of the Century")
  }
  Err(e) => println("解析或查询出错: \{e}")
}
```

## 支持的查询语法

当前版本支持的 JSONPath 核心操作符如下：

| 语法标识 | 描述 | 示例 |
| :--- | :--- | :--- |
| `$` | 根节点，所有查询的起始位置。 | `$` |
| `.<name>` | 访问对象中的指定字段。 | `$.store.bicycle` |
| `['<name>']`| 访问对象中的指定字段（适用于带特殊字符的键名）。| `$['store']['book']` |
| `..` | 递归搜索当前树下的所有匹配节点。 | `$..price` |
| `.*` / `[*]` | 通配符，匹配所有字段或数组元素。 | `$.store.book[*]` |
| `[<number>]`| 通过数组下标访问元素。 | `$..book[1]` |

### 更多使用场景

提取所有层级中的 `price` 字段：
```moonbit
let all_prices = @jsonpath.query(json, "$..price").unwrap()
```

获取所有的 book 对象：
```moonbit
let all_books = @jsonpath.query(json, "$.store.book[*]").unwrap()
```

## 代码结构说明

本项目主要分为以下几个模块：

*   `ast.mbt`：定义了 JSONPath 的抽象语法树节点。
*   `parser.mbt`：基于递归下降算法实现的解析器，将字符串解析为 AST 结构。
*   `eval.mbt`：执行引擎，负责遍历 `@json.Json` 数据并根据 AST 过滤出目标节点。
*   `jsonpath.mbt`：对外暴露的 `query` 函数入口。
*   `jsonpath_test.mbt`：包含针对核心功能的测试用例。

## 后续计划

- [ ] 支持更复杂的过滤器表达式 (例如 `[?(@.price < 10)]`)。
- [ ] 支持数组的多选切片 (例如 `[0:5:2]`, `[0,1]`)。

## 许可证

本项目采用 Apache-2.0 许可证进行开源。