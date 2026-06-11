# MoonBit JSONPath

一款高性能、纯函数式、类型安全的 JSONPath 解析与执行引擎，专为 MoonBit 生态系统量身定制。它完全遵循 RFC 9535 标准的核心子集，允许你以声明式和直观的方式从复杂的 JSON 数据结构中查询、过滤和提取所需的数据。

## 特色

- **符合行业标准**：核心逻辑严格按照 RFC 9535 规范设计，支持常见的点表示法 (`$.store.book`) 和括号表示法 (`$['store']['book']`)。
- **纯函数式实现**：核心引擎基于深度优先遍历与强大的模式匹配机制构建，避免了全局副作用，代码运行安全且极具表现力。
- **类型安全**：深度结合 MoonBit 优秀的类型系统，完全适配 MoonBit 标准库中的 `@json.Json` 类型，保证运行时解析零崩溃。
- **零外部依赖**：100% 纯 MoonBit 编写，除标准库外不依赖任何第三方包，完全准备好用于高性能 WebAssembly 编译与云原生执行环境。
- **支持复杂查询**：包含多层嵌套解析、通配符支持 (`*`)、数组索引查询以及递归下降 (`..`) 的全套基础能力。

## 安装

你可以通过 `moon` 包管理器将本引擎引入到你的 MoonBit 项目中：

```bash
moon add ppyj663/jsonpath
```

然后在你的项目的 `moon.pkg.json` 文件中添加依赖：

```json
{
  "import": [
    "ppyj663/jsonpath"
  ]
}
```

## 快速入门

只需解析 JSON 字符串并调用 `query` 函数即可快速查询：

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

// 1. 解析字符串体为 @json.Json
let json = @json.parse!(json_str)

// 2. 调用 JSONPath 进行数据查询
match @jsonpath.query(json, "$.store.book[0].title") {
  Ok(res) => {
    // res 的类型为 Array[Json]
    println("查询成功! 找到 \{res.length()} 个匹配项:")
    println(res[0]) // 输出 Json::String("Sayings of the Century")
  }
  Err(e) => println("JSONPath 解析或执行失败: \{e}")
}
```

## 支持的语法参考

本项目目前支持的 JSONPath 核心语法如下表所示：

| 语法标识 | 描述说明 | 示例 |
| :--- | :--- | :--- |
| `$` | 表示 JSON 树的根节点，所有路径的起始符号 | `$` |
| `.` 或 `[]` | 子节点访问符。访问字典对象中的指定字段 | `$.store` 或 `$['store']` |
| `..` | 递归下降访问符，在整个子树中深度搜索指定属性 | `$..price` |
| `*` | 通配符。返回对象中的所有值，或数组中的所有元素 | `$.store.book[*]` |
| `[<number>]` | 数组索引访问符。通过从0开始的下标获取数组元素 | `$..book[1]` |

### 更多查询示例

提取所有的 `price` 属性（深度优先搜索）：
```moonbit
let all_prices = @jsonpath.query(json, "$..price").unwrap()
```

获取所有的 `book` 对象：
```moonbit
let all_books = @jsonpath.query(json, "$.store.book[*]").unwrap()
```

## 架构与原理

本引擎采用了经典的编译器前端三段式架构，将复杂的查询解耦：
1. **抽象语法树 (AST)**：`ast.mbt` 定义了所有合法的 JSONPath 语法分量。
2. **递归下降解析器**：`parser.mbt` 对输入字符串进行单遍扫描解析，转换为安全、可控的 AST 结构，同时负责词法的异常拦截。
3. **求值与执行器**：`eval.mbt` 基于生成的 AST，针对输入的 `@json.Json` 目标化执行，收集树中符合条件的所有元素并组装返回。

## 贡献与反馈

欢迎任何关于性能优化、Filter Expressions（如 `[?(@.price < 10)]`）等高级功能的 Issue 和 PR。  
2026 MoonBit 编程挑战赛参赛项目。
---
# Documentation
|Type|description|
|---|---|
|[PathSegment](#PathSegment)||
|[JSONPath](#JSONPath)||

|Value|description|
|---|---|
|[evaluate](#evaluate)||
|[parse](#parse)||
|[query](#query)||

## PathSegment

```moonbit
:::source,username/jsonpath/ast.mbt,1:::pub enum PathSegment {
  Root
  Child(String)
  Descendant(String)
  Index(Int)
  Wildcard
} derive(<a href="moonbitlang/core/builtin#Eq">Eq</a>, <a href="moonbitlang/core/debug#Debug">@moonbitlang/core/debug.Debug</a>)
```


## JSONPath

```moonbit
:::source,username/jsonpath/ast.mbt,9:::type JSONPath = <a href="moonbitlang/core/builtin#Array">Array</a>[<a href="username/jsonpath#PathSegment">PathSegment</a>]
```

 An `Array` is a collection of values that supports random access and can
grow in size.

## evaluate

```moonbit
:::source,username/jsonpath/eval.mbt,1:::fn evaluate(json : <a href="moonbitlang/core/builtin#Json">Json</a>, path : <a href="moonbitlang/core/builtin#Array">Array</a>[<a href="username/jsonpath#PathSegment">PathSegment</a>]) -> <a href="moonbitlang/core/builtin#Array">Array</a>[<a href="moonbitlang/core/builtin#Json">Json</a>]
```


## parse

```moonbit
:::source,username/jsonpath/parser.mbt,1:::fn parse(input : String) -> Result[<a href="moonbitlang/core/builtin#Array">Array</a>[<a href="username/jsonpath#PathSegment">PathSegment</a>], String]
```


## query

```moonbit
:::source,username/jsonpath/jsonpath.mbt,1:::fn query(json : <a href="moonbitlang/core/builtin#Json">Json</a>, path_str : String) -> Result[<a href="moonbitlang/core/builtin#Array">Array</a>[<a href="moonbitlang/core/builtin#Json">Json</a>], String]
```

