# MoonBit JSONPath

[![MoonBit Version](https://img.shields.io/badge/MoonBit-2024+-blue.svg)](https://www.moonbitlang.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)
[![Status](https://img.shields.io/badge/Status-Active-success.svg)]()

一款**高性能、纯函数式、类型安全**的 JSONPath 解析与执行核心引擎，专为 MoonBit 生态系统量身定制。它完全遵循 [RFC 9535 标准](https://www.rfc-editor.org/rfc/rfc9535) 的核心子集，为您提供了一个优雅、声明式且直观的 API，用于从复杂的嵌套 JSON 数据结构中查询、过滤和提取所需的数据。

无论是用于微服务架构下的复杂 JSON API 响应字段精准提取、前端配置动态路由查询，还是云原生系统中的高频日志过滤，本库都能胜任。

---

## ✨ 核心特色 (Features)

*   **🛡️ 类型安全与零崩溃**：深度结合 MoonBit 优秀的类型系统，完全适配 MoonBit 官方 `@json.Json` 类型。纯函数式的内部状态流转，避免了运行时 Panic。
*   **🚀 极致性能零依赖**：100% 纯 MoonBit 编写，除了标准库以外**不依赖任何第三方包**。完全契合高性能 WebAssembly (Wasm) 编译后端，体积小巧，加载极速。
*   **🌳 全面的语法支持**：核心逻辑严格按照 RFC 9535 规范设计，不仅支持点表示法 (`$.store.book`) 和括号表示法 (`$['store']['book']`)，更支持深度递归搜索 (`..`)、通配符提取 (`*`) 以及数组精确索引定位 (`[number]`)。
*   **🔧 模块化工程架构**：编译器级的三段式架构设计——词法/语法解析器 (Parser) -> 抽象语法树 (AST) -> 执行器引擎 (Evaluator)，底层逻辑极其清晰，为后续二次开发或增加 `Filter` 引擎打下了坚实基础。

---

## 📦 安装指南

得益于 MoonBit 的包管理器，您可以零配置将本引擎引入到您的项目中。

```bash
moon add ppyj663/jsonpath
```

安装完成后，请在您项目所在模块的 `moon.pkg.json` 文件中添加引入依赖：

```json
{
  "import": [
    "ppyj663/jsonpath"
  ]
}
```

---

## ⚡ 快速入门

只需解析 JSON 字符串并调用暴露的 `query` 函数即可轻松从海量数据中过滤出您的目标节点！

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

// 1. 调用内置标准库将字符串体解析为 @json.Json
let json = @json.parse!(json_str)

// 2. 调用 JSONPath 引擎进行数据抽取
match @jsonpath.query(json, "$.store.book[0].title") {
  Ok(res) => {
    // 返回的结果 res 为 Array[Json] 格式
    println("🎉 查询成功! 找到 \{res.length()} 个匹配项:")
    println(res[0]) // => 输出: Json::String("Sayings of the Century")
  }
  Err(e) => println("❌ JSONPath 解析或执行失败: \{e}")
}
```

---

## 📖 高级查询语法参考

本项目目前全面支持的 JSONPath 核心语法与操作符如下表所示：

| 语法标识 | 名称 | 描述说明 | 查询示例 |
| :--- | :--- | :--- | :--- |
| `$` | **根节点** | 表示 JSON 树的根节点，所有路径规则的起始符号。 | `$` |
| `.<name>` | **点号子节点访问** | 访问字典对象(Object)中的指定字段。 | `$.store.bicycle` |
| `['<name>']`| **括号子节点访问** | 访问字典对象中的指定字段，完美支持包含特殊字符的 Key。| `$['store']['book']` |
| `..` | **递归下降访问** | 穿越所有嵌套层级，在整个子树中深度搜索指定属性。 | `$..price` |
| `.*` / `[*]` | **通配符** | 遍历并返回当前对象中的所有 Values，或数组中的所有元素。 | `$.store.book[*]` |
| `[<number>]`| **数组索引访问** | 通过从 0 开始的数字下标，精准提取数组内部对象。 | `$..book[1]` |

### 🔍 复杂查询场景演示

**场景 A：深度提取所有商品价格（无论是书籍还是自行车）**
无论 `price` 属性埋藏在多深的层级，`..` 操作符都能将其全数捞出：
```moonbit
let all_prices = @jsonpath.query(json, "$..price").unwrap()
// 引擎将返回包含 [8.95, 12.99, 19.95] 的 Json 数组
```

**场景 B：利用通配符全量拉取某分类下的子项**
当面对不确定数量的数组元素时：
```moonbit
let all_books = @jsonpath.query(json, "$.store.book[*]").unwrap()
// 将返回书店下所有两本书的完整 Json::Object
```

---

## 🏗️ 核心架构与原理解析

作为一款参加 2026 MoonBit 编程挑战赛的高质量原创项目，在底层实现上我们严格遵循了《编译原理》的最佳实践，将执行过程完全解耦为三个微型系统：

1. **抽象语法树构建 (AST) - `ast.mbt`**
   定义了所有合法的 JSONPath 语法分量 (如 `PathSegment::Child`, `PathSegment::Descendant`)，形成结构化数据，确保数据在编译器内部流通时的类型安全性。
   
2. **纯手写的高性能递归下降解析器 - `parser.mbt`**
   摒弃了沉重的正则引擎，对输入字符串进行 `O(N)` 时间复杂度的单遍字符流扫描。实现了包含非法边界探测、容错拦截以及动态分词的功能。
   
3. **基于模式匹配的解释器引擎 - `eval.mbt`**
   基于 MoonBit 强大的 Pattern Matching 能力，对输入的 `@json.Json` 树进行精准裁切。引擎底层全面抛弃可变全局状态，采用迭代配合尾递归的函数式搜索，内存占用极低。

---

## 📂 项目目录结构

```text
jsonpath/
├── ast.mbt             # AST 数据结构定义
├── parser.mbt          # 递归下降语法解析器
├── eval.mbt            # 核心寻址与求值引擎
├── jsonpath.mbt        # 暴露的对外的公共 API 接口 (Facade)
├── jsonpath_test.mbt   # 100% 覆盖核心语法的 TDD 自动化测试用例
├── README.md           # 详尽的说明文档
├── report.pdf          # 项目参赛申报说明书
└── moon.pkg.json       # MoonBit 现代化包管理配置
```

---

## 🎯 未来演进规划 (Roadmap)

我们正致力于打造整个 MoonBit 生态中最卓越的 JSON 数据抽取器，未来计划支持：
- [ ] **过滤器表达式 (Filter Expressions)**: 支持类似于 `[?(@.price < 10)]` 这种在路径内部嵌入复杂判断和比对逻辑的表达式引擎。
- [ ] **多选切片提取 (Array Slices)**: 支持像 `[0:5:2]` 或 `[0,1]` 等高级切片和联合数组获取特性。
- [ ] JIT (即时编译) 查询缓存优化。

## 📜 许可证

本项目开源并遵循 **Apache-2.0 License** 协议。您可以自由地在商业或非商业项目中集成使用。

---
*Created for the 2026 MoonBit Open Source Competition - Track 1.*