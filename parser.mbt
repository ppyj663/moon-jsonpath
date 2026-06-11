pub fn parse(input : String) -> Result[JSONPath, String] {
  let len = input.length()
  if len == 0 || input[0].to_int() != '$'.to_int() {
    return Err("JSONPath must start with '$'")
  }
  let segments = [PathSegment::Root]
  Ok(segments)
}
