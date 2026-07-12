///|
suberror ParseError {
  ParseError(String)
} derive(Debug)

///|
priv struct Parser {
  input : String
  len : Int
  mut i : Int
}

///|
fn Parser::new(input : String) -> Parser {
  { input, len: input.length(), i: 0 }
}

///|
fn Parser::peek(self : Parser) -> Char? {
  if self.i < self.len {
    Some(self.input[self.i].to_int().unsafe_to_char())
  } else {
    None
  }
}

///|
fn Parser::next(self : Parser) -> Char? {
  if self.i < self.len {
    let c = self.input[self.i].to_int().unsafe_to_char()
    self.i = self.i + 1
    Some(c)
  } else {
    None
  }
}

///|
fn Parser::skip_whitespace(self : Parser) -> Unit {
  while self.i < self.len {
    let c = self.input[self.i].to_int().unsafe_to_char()
    if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
      self.i = self.i + 1
    } else {
      break
    }
  }
}

///|
fn Parser::read_ident(self : Parser) -> String {
  let start = self.i
  if self.i >= self.len {
    return ""
  }
  let c = self.input[self.i].to_int().unsafe_to_char()
  if !is_ident_start_char(c) {
    return ""
  }
  self.i = self.i + 1
  while self.i < self.len {
    let ch = self.input[self.i].to_int().unsafe_to_char()
    if is_ident_char(ch) {
      self.i = self.i + 1
    } else {
      break
    }
  }
  self.input[start:self.i].to_owned()
}

///|
fn is_ident_start_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
}

///|
fn is_ident_char(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') ||
  (c >= 'A' && c <= 'Z') ||
  (c >= '0' && c <= '9') ||
  c == '_' ||
  c == '-'
}

///|
fn Parser::parse_integer(self : Parser) -> Int raise ParseError {
  self.skip_whitespace()
  let p = self.peek()
  if p == None {
    raise ParseError("Expected integer")
  }
  let mut is_neg = false
  let c = p.unwrap()
  if c == '-' {
    is_neg = true
    self.i = self.i + 1
  } else if c == '+' {
    self.i = self.i + 1
  }
  let mut val = 0
  let mut has_digit = false
  while self.i < self.len {
    let ch = self.input[self.i].to_int().unsafe_to_char()
    if ch >= '0' && ch <= '9' {
      val = val * 10 + (ch.to_int() - 48)
      has_digit = true
      self.i = self.i + 1
    } else {
      break
    }
  }
  if !has_digit {
    raise ParseError("Expected digit in integer")
  }
  if is_neg {
    -val
  } else {
    val
  }
}

///|
fn Parser::parse_string_literal(self : Parser) -> String raise ParseError {
  let quote = self.next().unwrap()
  let mut s = ""
  while self.i < self.len {
    let c = self.input[self.i].to_int().unsafe_to_char()
    if c == quote {
      self.i = self.i + 1
      return s
    }
    if c == '\\' {
      self.i = self.i + 1
      if self.i >= self.len {
        raise ParseError("Unterminated string escape sequence")
      }
      let esc = self.input[self.i].to_int().unsafe_to_char()
      self.i = self.i + 1
      match esc {
        'n' => s = s + "\n"
        't' => s = s + "\t"
        'r' => s = s + "\r"
        'b' => s = s + "\u0008"
        'f' => s = s + "\u000c"
        '/' => s = s + "/"
        '\\' => s = s + "\\"
        '\'' => s = s + "'"
        '"' => s = s + "\""
        'u' => {
          if self.i + 4 > self.len {
            raise ParseError("Invalid unicode escape sequence")
          }
          let hex = self.input[self.i:self.i + 4].to_owned()
          self.i = self.i + 4
          let mut code = 0
          for k = 0; k < 4; k = k + 1 {
            let h = hex[k].to_int().unsafe_to_char()
            let digit = if h >= '0' && h <= '9' {
              h.to_int() - 48
            } else if h >= 'a' && h <= 'f' {
              h.to_int() - 97 + 10
            } else if h >= 'A' && h <= 'F' {
              h.to_int() - 65 + 10
            } else {
              raise ParseError("Invalid hex digit in unicode escape")
            }
            code = code * 16 + digit
          }
          s = s + code.unsafe_to_char().to_string()
        }
        _ => raise ParseError("Unknown escape sequence: \\" + esc.to_string())
      }
    } else {
      s = s + c.to_string()
      self.i = self.i + 1
    }
  }
  raise ParseError("Unterminated string literal")
}

///|
fn Parser::parse_path(
  self : Parser,
  expected_start : Char,
) -> JSONPath raise ParseError {
  self.skip_whitespace()
  match self.next() {
    Some(c) =>
      if c != expected_start {
        raise ParseError(
          "Expected path starting with '" + expected_start.to_string() + "'",
        )
      }
    None =>
      raise ParseError(
        "Expected path starting with '" +
        expected_start.to_string() +
        "', got empty input",
      )
  }
  let segments = [Root]
  while self.i < self.len {
    self.skip_whitespace()
    let p = self.peek()
    if p == None {
      break
    }
    let c = p.unwrap()
    if c == '.' {
      self.i = self.i + 1
      let is_descendant = match self.peek() {
        Some('.') => {
          self.i = self.i + 1
          true
        }
        _ => false
      }
      self.skip_whitespace()
      match self.peek() {
        Some('*') => {
          self.i = self.i + 1
          if is_descendant {
            segments.push(DescendantWildcard)
          } else {
            segments.push(Wildcard)
          }
        }
        Some('[') => {
          let bracket_sel = self.parse_bracket_segment()
          match bracket_sel {
            Bracket(selectors) =>
              if is_descendant {
                segments.push(DescendantBracket(selectors))
              } else {
                segments.push(Bracket(selectors))
              }
            _ => raise ParseError("Expected bracket selectors")
          }
        }
        _ => {
          let name = self.read_ident()
          if name == "" {
            raise ParseError("Expected identifier after '.' or '..'")
          }
          if is_descendant {
            segments.push(Descendant(name))
          } else {
            segments.push(Child(name))
          }
        }
      }
    } else if c == '[' {
      let bracket_sel = self.parse_bracket_segment()
      segments.push(bracket_sel)
    } else {
      break
    }
  }
  segments
}

///|
fn Parser::parse_bracket_segment(self : Parser) -> PathSegment raise ParseError {
  self.i = self.i + 1
  self.skip_whitespace()
  let selectors = []
  while true {
    let sel = self.parse_selector()
    selectors.push(sel)
    self.skip_whitespace()
    match self.peek() {
      Some(',') => {
        self.i = self.i + 1
        self.skip_whitespace()
      }
      Some(']') => {
        self.i = self.i + 1
        break
      }
      _ => raise ParseError("Expected ',' or ']' inside bracket selector")
    }
  }
  Bracket(selectors)
}

///|
fn Parser::parse_selector(self : Parser) -> Selector raise ParseError {
  self.skip_whitespace()
  let p = self.peek()
  if p == None {
    raise ParseError("Unexpected end of input in bracket selector")
  }
  let c = p.unwrap()
  if c == '*' {
    self.i = self.i + 1
    return Wildcard
  }
  if c == '\'' || c == '"' {
    let str_val = self.parse_string_literal()
    return Name(str_val)
  }
  if c == '?' {
    self.i = self.i + 1
    self.skip_whitespace()
    match self.next() {
      Some('(') => ()
      _ => raise ParseError("Expected '(' after '?' in filter")
    }
    let expr = self.parse_filter_expr()
    self.skip_whitespace()
    match self.next() {
      Some(')') => ()
      _ => raise ParseError("Expected ')' to close filter expression")
    }
    return Filter(expr)
  }
  let has_sign = c == '-' || c == '+'
  if has_sign || (c >= '0' && c <= '9') || c == ':' {
    let start = if c != ':' {
      let val = self.parse_integer()
      Some(val)
    } else {
      None
    }
    self.skip_whitespace()
    match self.peek() {
      Some(':') => {
        self.i = self.i + 1
        self.skip_whitespace()
        let end = if self.peek() != Some(':') &&
          self.peek() != Some(']') &&
          self.peek() != Some(',') {
          let val = self.parse_integer()
          Some(val)
        } else {
          None
        }
        self.skip_whitespace()
        let step = match self.peek() {
          Some(':') => {
            self.i = self.i + 1
            self.skip_whitespace()
            let val = self.parse_integer()
            Some(val)
          }
          _ => None
        }
        return Slice(start, end, step)
      }
      _ =>
        match start {
          Some(val) => return Index(val)
          None => raise ParseError("Invalid index/slice inside brackets")
        }
    }
  }
  raise ParseError("Unsupported or invalid selector: '" + c.to_string() + "'")
}

///|
fn filter_expr_to_val(expr : FilterExpr) -> FilterVal raise ParseError {
  match expr {
    Value(val) => val
    Exists(path) => Path(path)
    _ =>
      raise ParseError(
        "Expected value or path in comparison, got complex expression",
      )
  }
}

///|
fn Parser::parse_filter_expr(self : Parser) -> FilterExpr raise ParseError {
  self.parse_filter_or()
}

///|
fn Parser::parse_filter_or(self : Parser) -> FilterExpr raise ParseError {
  let mut expr = self.parse_filter_and()
  while true {
    self.skip_whitespace()
    if self.i + 2 <= self.len && self.input[self.i:self.i + 2] == "||" {
      self.i = self.i + 2
      let right = self.parse_filter_and()
      expr = Or(expr, right)
    } else {
      break
    }
  }
  expr
}

///|
fn Parser::parse_filter_and(self : Parser) -> FilterExpr raise ParseError {
  let mut expr = self.parse_filter_comparison()
  while true {
    self.skip_whitespace()
    if self.i + 2 <= self.len && self.input[self.i:self.i + 2] == "&&" {
      self.i = self.i + 2
      let right = self.parse_filter_comparison()
      expr = And(expr, right)
    } else {
      break
    }
  }
  expr
}

///|
fn Parser::parse_filter_comparison(
  self : Parser,
) -> FilterExpr raise ParseError {
  self.skip_whitespace()
  let left = self.parse_filter_unary()

  self.skip_whitespace()
  let op_str2 = if self.i + 2 <= self.len {
    self.input[self.i:self.i + 2]
  } else {
    ""
  }

  if op_str2 == "==" {
    self.i = self.i + 2
    let right = self.parse_filter_unary()
    let left_val = filter_expr_to_val(left)
    let right_val = filter_expr_to_val(right)
    return Eq(left_val, right_val)
  }
  if op_str2 == "!=" {
    self.i = self.i + 2
    let right = self.parse_filter_unary()
    let left_val = filter_expr_to_val(left)
    let right_val = filter_expr_to_val(right)
    return Ne(left_val, right_val)
  }
  if op_str2 == "<=" {
    self.i = self.i + 2
    let right = self.parse_filter_unary()
    let left_val = filter_expr_to_val(left)
    let right_val = filter_expr_to_val(right)
    return Le(left_val, right_val)
  }
  if op_str2 == ">=" {
    self.i = self.i + 2
    let right = self.parse_filter_unary()
    let left_val = filter_expr_to_val(left)
    let right_val = filter_expr_to_val(right)
    return Ge(left_val, right_val)
  }

  let op_str1 = if self.i < self.len {
    self.input[self.i].to_int().unsafe_to_char().to_string()
  } else {
    ""
  }

  if op_str1 == "<" {
    self.i = self.i + 1
    let right = self.parse_filter_unary()
    let left_val = filter_expr_to_val(left)
    let right_val = filter_expr_to_val(right)
    return Lt(left_val, right_val)
  }
  if op_str1 == ">" {
    self.i = self.i + 1
    let right = self.parse_filter_unary()
    let left_val = filter_expr_to_val(left)
    let right_val = filter_expr_to_val(right)
    return Gt(left_val, right_val)
  }

  left
}

///|
fn Parser::parse_filter_unary(self : Parser) -> FilterExpr raise ParseError {
  self.skip_whitespace()
  if self.peek() == Some('!') {
    if self.i + 2 <= self.len && self.input[self.i:self.i + 2] == "!=" {
      // comparison
    } else {
      self.i = self.i + 1
      let sub = self.parse_filter_unary()
      return Not(sub)
    }
  }
  self.parse_filter_primary()
}

///|
fn Parser::parse_filter_primary(self : Parser) -> FilterExpr raise ParseError {
  self.skip_whitespace()
  let p = self.peek()
  if p == None {
    raise ParseError("Unexpected end of input in filter expression")
  }
  let c = p.unwrap()
  if c == '(' {
    self.i = self.i + 1
    let sub = self.parse_filter_expr()
    self.skip_whitespace()
    match self.next() {
      Some(')') => sub
      _ => raise ParseError("Expected ')' to close parenthesis")
    }
  } else if c == '@' {
    let path = self.parse_path_expr()
    Exists(path)
  } else if c == '$' {
    let path = self.parse_path_expr()
    Exists(path)
  } else {
    let lit = self.parse_json_literal()
    Value(Literal(lit))
  }
}

///|
fn Parser::parse_path_expr(self : Parser) -> PathExpr raise ParseError {
  self.skip_whitespace()
  let p = self.peek()
  if p == None {
    raise ParseError("Expected path expression")
  }
  let c = p.unwrap()
  if c == '@' {
    let path = self.parse_path('@')
    Relative(path)
  } else if c == '$' {
    let path = self.parse_path('$')
    Absolute(path)
  } else {
    raise ParseError("Expected path starting with '@' or '$'")
  }
}

///|
fn Parser::parse_json_literal(self : Parser) -> Json raise ParseError {
  self.skip_whitespace()
  let p = self.peek()
  if p == None {
    raise ParseError("Expected JSON literal")
  }
  let c = p.unwrap()
  if c == '\'' || c == '"' {
    let s = self.parse_string_literal()
    return s.to_json()
  }
  if self.i + 4 <= self.len && self.input[self.i:self.i + 4] == "null" {
    self.i = self.i + 4
    return null
  }
  if self.i + 4 <= self.len && self.input[self.i:self.i + 4] == "true" {
    self.i = self.i + 4
    return true
  }
  if self.i + 5 <= self.len && self.input[self.i:self.i + 5] == "false" {
    self.i = self.i + 5
    return false
  }
  if c == '-' || c == '+' || (c >= '0' && c <= '9') {
    let mut is_neg = false
    if c == '-' {
      is_neg = true
      self.i = self.i + 1
    } else if c == '+' {
      self.i = self.i + 1
    }
    let mut num_str = ""
    while self.i < self.len {
      let ch = self.input[self.i].to_int().unsafe_to_char()
      if ch >= '0' && ch <= '9' {
        num_str = num_str + ch.to_string()
        self.i = self.i + 1
      } else {
        break
      }
    }
    if num_str == "" {
      raise ParseError("Expected digits in number literal")
    }
    if self.i < self.len && self.input[self.i].to_int().unsafe_to_char() == '.' {
      num_str = num_str + "."
      self.i = self.i + 1
      let mut has_frac_digit = false
      while self.i < self.len {
        let ch = self.input[self.i].to_int().unsafe_to_char()
        if ch >= '0' && ch <= '9' {
          num_str = num_str + ch.to_string()
          has_frac_digit = true
          self.i = self.i + 1
        } else {
          break
        }
      }
      if !has_frac_digit {
        raise ParseError("Expected digits after '.' in decimal number")
      }
    }
    let double_str = if is_neg { "-" + num_str } else { num_str }
    try {
      let val = @string.parse_double(double_str)
      val.to_json()
    } catch {
      _ => raise ParseError("Invalid double literal: " + double_str)
    }
  } else {
    raise ParseError("Unexpected literal character: " + c.to_string())
  }
}

///|
pub fn parse(input : String) -> Result[JSONPath, String] {
  let parser = Parser::new(input)
  try {
    let path = parser.parse_path('$')
    parser.skip_whitespace()
    if parser.i < parser.len {
      raise ParseError("Unexpected characters at end of JSONPath")
    }
    Ok(path)
  } catch {
    ParseError(err) => Err(err)
  }
}
