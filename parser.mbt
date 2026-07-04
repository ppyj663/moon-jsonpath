///|
pub fn parse(input : String) -> Result[JSONPath, String] {
  let len = input.length()
  if len == 0 || input[0].to_int() != '$'.to_int() {
    return Err("JSONPath must start with '$'")
  }
  let segments = [Root]
  let mut i = 1
  while i < len {
    let c = input[i].to_int()
    if c == '.'.to_int() {
      i = i + 1
      if i < len && input[i].to_int() == '.'.to_int() {
        i = i + 1
        let (name, next_i) = read_ident(input, i)
        if name == "" {
          return Err("Expected identifier after '..'")
        }
        segments.push(Descendant(name))
        i = next_i
      } else if i < len && input[i].to_int() == '*'.to_int() {
        segments.push(Wildcard)
        i = i + 1
      } else {
        let (name, next_i) = read_ident(input, i)
        if name == "" {
          return Err("Expected identifier after '.'")
        }
        segments.push(Child(name))
        i = next_i
      }
    } else if c == '['.to_int() {
      i = i + 1
      if i < len && input[i].to_int() == '*'.to_int() {
        segments.push(Wildcard)
        i = i + 1
        if i < len && input[i].to_int() == ']'.to_int() {
          i = i + 1
        } else {
          return Err("Expected ']' after '*'")
        }
      } else if i < len &&
        (
          input[i].to_int() == '\''.to_int() ||
          input[i].to_int() == '"'.to_int()
        ) {
        let quote = input[i].to_int()
        i = i + 1
        let mut name = ""
        while i < len && input[i].to_int() != quote {
          name = name + input[i].to_int().unsafe_to_char().to_string()
          i = i + 1
        }
        if i < len && input[i].to_int() == quote {
          i = i + 1
        } else {
          return Err("Unterminated string literal")
        }
        if i < len && input[i].to_int() == ']'.to_int() {
          i = i + 1
        } else {
          return Err("Expected ']' after string literal")
        }
        segments.push(Child(name))
      } else if i < len && is_digit(input[i].to_int()) {
        let mut num = 0
        while i < len && is_digit(input[i].to_int()) {
          num = num * 10 + (input[i].to_int() - 48)
          i = i + 1
        }
        if i < len && input[i].to_int() == ']'.to_int() {
          i = i + 1
        } else {
          return Err("Expected ']' after number")
        }
        segments.push(Index(num))
      } else {
        return Err("Unsupported syntax inside '['")
      }
    } else {
      return Err("Unexpected character")
    }
  }
  Ok(segments)
}

///|
fn read_ident(input : String, start : Int) -> (String, Int) {
  let len = input.length()
  let mut i = start
  let mut ident = ""
  while i < len && is_ident_char(input[i].to_int()) {
    ident = ident + input[i].to_int().unsafe_to_char().to_string()
    i = i + 1
  }
  (ident, i)
}

///|
fn is_ident_char(c : Int) -> Bool {
  (c >= 'a'.to_int() && c <= 'z'.to_int()) ||
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= '0'.to_int() && c <= '9'.to_int()) ||
  c == '_'.to_int() ||
  c == '-'.to_int()
}

///|
fn is_digit(c : Int) -> Bool {
  c >= '0'.to_int() && c <= '9'.to_int()
}
