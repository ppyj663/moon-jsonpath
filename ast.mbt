pub enum PathSegment {
  Root
  Child(String)
  Descendant(String)
  Index(Int)
  Wildcard
} derive(Eq, @debug.Debug)

pub type JSONPath = Array[PathSegment]
