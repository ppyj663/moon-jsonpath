///|
pub enum PathSegment {
  Root
  Child(String)
  Descendant(String)
  Wildcard
  DescendantWildcard
  Bracket(Array[Selector])
  DescendantBracket(Array[Selector])
} derive(Eq, @debug.Debug)

///|
pub enum Selector {
  Name(String)
  Index(Int)
  Wildcard
  Slice(Int?, Int?, Int?)
  Filter(FilterExpr)
} derive(Eq, @debug.Debug)

///|
pub enum FilterExpr {
  Exists(PathExpr)
  Eq(FilterVal, FilterVal)
  Ne(FilterVal, FilterVal)
  Lt(FilterVal, FilterVal)
  Le(FilterVal, FilterVal)
  Gt(FilterVal, FilterVal)
  Ge(FilterVal, FilterVal)
  And(FilterExpr, FilterExpr)
  Or(FilterExpr, FilterExpr)
  Not(FilterExpr)
  Value(FilterVal)
} derive(Eq, @debug.Debug)

///|
pub enum FilterVal {
  Path(PathExpr)
  Literal(Json)
} derive(Eq, @debug.Debug)

///|
pub enum PathExpr {
  Relative(JSONPath)
  Absolute(JSONPath)
} derive(Eq, @debug.Debug)

///|
pub type JSONPath = Array[PathSegment]
