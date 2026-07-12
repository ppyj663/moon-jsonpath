///|
pub fn evaluate(json : Json, path : JSONPath) -> Array[Json] {
  evaluate_with_root(json, path, json)
}

///|
fn evaluate_with_root(
  json : Json,
  path : JSONPath,
  global_root : Json,
) -> Array[Json] {
  let mut current = [json]
  for i = 0; i < path.length(); i = i + 1 {
    let segment = path[i]
    let next = []
    for j = 0; j < current.length(); j = j + 1 {
      let node = current[j]
      match segment {
        Root => next.push(node)
        Child(name) =>
          match node {
            Object(obj) =>
              match obj.get(name) {
                Some(val) => next.push(val)
                None => ()
              }
            _ => ()
          }
        Descendant(name) => find_descendants_child(node, name, next)
        Wildcard =>
          match node {
            Object(obj) =>
              for _, val in obj {
                next.push(val)
              }
            Array(arr) =>
              for val in arr {
                next.push(val)
              }
            _ => ()
          }
        DescendantWildcard => find_descendants_wildcard(node, next)
        Bracket(selectors) => {
          let matches = evaluate_bracket(node, selectors, global_root)
          for m in matches {
            next.push(m)
          }
        }
        DescendantBracket(selectors) =>
          find_descendants_bracket(node, selectors, next, global_root)
      }
    }
    current = next
  }
  current
}

///|
fn find_descendants_child(
  node : Json,
  name : String,
  acc : Array[Json],
) -> Unit {
  match node {
    Object(obj) => {
      match obj.get(name) {
        Some(val) => acc.push(val)
        None => ()
      }
      for _, val in obj {
        find_descendants_child(val, name, acc)
      }
    }
    Array(arr) =>
      for val in arr {
        find_descendants_child(val, name, acc)
      }
    _ => ()
  }
}

///|
fn find_descendants_wildcard(node : Json, acc : Array[Json]) -> Unit {
  match node {
    Object(obj) =>
      for _, val in obj {
        acc.push(val)
        find_descendants_wildcard(val, acc)
      }
    Array(arr) =>
      for val in arr {
        acc.push(val)
        find_descendants_wildcard(val, acc)
      }
    _ => ()
  }
}

///|
fn find_descendants_bracket(
  node : Json,
  selectors : Array[Selector],
  acc : Array[Json],
  global_root : Json,
) -> Unit {
  let current_matches = evaluate_bracket(node, selectors, global_root)
  for m in current_matches {
    acc.push(m)
  }
  match node {
    Object(obj) =>
      for _, val in obj {
        find_descendants_bracket(val, selectors, acc, global_root)
      }
    Array(arr) =>
      for val in arr {
        find_descendants_bracket(val, selectors, acc, global_root)
      }
    _ => ()
  }
}

///|
fn evaluate_bracket(
  node : Json,
  selectors : Array[Selector],
  global_root : Json,
) -> Array[Json] {
  let acc = []
  for selector in selectors {
    match selector {
      Name(name) =>
        match node {
          Object(obj) =>
            match obj.get(name) {
              Some(val) => acc.push(val)
              None => ()
            }
          _ => ()
        }
      Index(idx) =>
        match node {
          Array(arr) => {
            let len = arr.length()
            let resolved_idx = if idx < 0 { len + idx } else { idx }
            if resolved_idx >= 0 && resolved_idx < len {
              acc.push(arr[resolved_idx])
            }
          }
          _ => ()
        }
      Wildcard =>
        match node {
          Object(obj) =>
            for _, val in obj {
              acc.push(val)
            }
          Array(arr) =>
            for val in arr {
              acc.push(val)
            }
          _ => ()
        }
      Slice(start_opt, end_opt, step_opt) =>
        match node {
          Array(arr) => {
            let len = arr.length()
            let step = match step_opt {
              Some(s) => s
              None => 1
            }
            if step != 0 {
              if step > 0 {
                let start = match start_opt {
                  Some(s) =>
                    if s < 0 {
                      let r = len + s
                      if r < 0 {
                        0
                      } else {
                        r
                      }
                    } else if s > len {
                      len
                    } else {
                      s
                    }
                  None => 0
                }
                let end = match end_opt {
                  Some(e) =>
                    if e < 0 {
                      let r = len + e
                      if r < 0 {
                        0
                      } else {
                        r
                      }
                    } else if e > len {
                      len
                    } else {
                      e
                    }
                  None => len
                }
                let mut idx = start
                while idx < end {
                  acc.push(arr[idx])
                  idx = idx + step
                }
              } else {
                let start = match start_opt {
                  Some(s) =>
                    if s < 0 {
                      let r = len + s
                      if r < -1 {
                        -1
                      } else {
                        r
                      }
                    } else if s >= len {
                      len - 1
                    } else {
                      s
                    }
                  None => len - 1
                }
                let end = match end_opt {
                  Some(e) =>
                    if e < 0 {
                      let r = len + e
                      if r < -1 {
                        -1
                      } else {
                        r
                      }
                    } else if e >= len {
                      len - 1
                    } else {
                      e
                    }
                  None => -1
                }
                let mut idx = start
                while idx > end {
                  acc.push(arr[idx])
                  idx = idx + step
                }
              }
            }
          }
          _ => ()
        }
      Filter(expr) =>
        match node {
          Array(arr) =>
            for val in arr {
              if evaluate_filter(val, expr, global_root) {
                acc.push(val)
              }
            }
          Object(obj) =>
            for _, val in obj {
              if evaluate_filter(val, expr, global_root) {
                acc.push(val)
              }
            }
          _ => ()
        }
    }
  }
  acc
}

///|
fn evaluate_filter(
  curr_node : Json,
  expr : FilterExpr,
  global_root : Json,
) -> Bool {
  match expr {
    Exists(path) => {
      let results = evaluate_path_expr(curr_node, path, global_root)
      results.length() > 0
    }
    Eq(left, right) => {
      let l = evaluate_filter_val(curr_node, left, global_root)
      let r = evaluate_filter_val(curr_node, right, global_root)
      compare_vals(l, r) == 0
    }
    Ne(left, right) => {
      let l = evaluate_filter_val(curr_node, left, global_root)
      let r = evaluate_filter_val(curr_node, right, global_root)
      compare_vals(l, r) != 0
    }
    Lt(left, right) => {
      let l = evaluate_filter_val(curr_node, left, global_root)
      let r = evaluate_filter_val(curr_node, right, global_root)
      match compare_vals(l, r) {
        -1 => true
        _ => false
      }
    }
    Le(left, right) => {
      let l = evaluate_filter_val(curr_node, left, global_root)
      let r = evaluate_filter_val(curr_node, right, global_root)
      match compare_vals(l, r) {
        -1 | 0 => true
        _ => false
      }
    }
    Gt(left, right) => {
      let l = evaluate_filter_val(curr_node, left, global_root)
      let r = evaluate_filter_val(curr_node, right, global_root)
      match compare_vals(l, r) {
        1 => true
        _ => false
      }
    }
    Ge(left, right) => {
      let l = evaluate_filter_val(curr_node, left, global_root)
      let r = evaluate_filter_val(curr_node, right, global_root)
      match compare_vals(l, r) {
        1 | 0 => true
        _ => false
      }
    }
    And(e1, e2) =>
      evaluate_filter(curr_node, e1, global_root) &&
      evaluate_filter(curr_node, e2, global_root)
    Or(e1, e2) =>
      evaluate_filter(curr_node, e1, global_root) ||
      evaluate_filter(curr_node, e2, global_root)
    Not(e) => !evaluate_filter(curr_node, e, global_root)
    Value(val) =>
      match evaluate_filter_val(curr_node, val, global_root) {
        Some(False) | Some(Null) | None => false
        _ => true
      }
  }
}

///|
fn evaluate_path_expr(
  curr_node : Json,
  path : PathExpr,
  global_root : Json,
) -> Array[Json] {
  match path {
    Relative(p) => evaluate_with_root(curr_node, p, global_root)
    Absolute(p) => evaluate_with_root(global_root, p, global_root)
  }
}

///|
fn evaluate_filter_val(
  curr_node : Json,
  val : FilterVal,
  global_root : Json,
) -> Json? {
  match val {
    Literal(json) => Some(json)
    Path(path) => {
      let results = evaluate_path_expr(curr_node, path, global_root)
      if results.length() == 1 {
        Some(results[0])
      } else if results.length() == 0 {
        None
      } else {
        Some(results.to_json())
      }
    }
  }
}

///|
fn compare_vals(val1 : Json?, val2 : Json?) -> Int {
  match (val1, val2) {
    (Some(v1), Some(v2)) =>
      match (v1, v2) {
        (Number(n1, ..), Number(n2, ..)) =>
          if n1 < n2 {
            -1
          } else if n1 > n2 {
            1
          } else {
            0
          }
        (String(s1), String(s2)) =>
          if s1 < s2 {
            -1
          } else if s1 > s2 {
            1
          } else {
            0
          }
        (True, True) => 0
        (False, False) => 0
        (Null, Null) => 0
        _ => if v1 == v2 { 0 } else { -2 }
      }
    (None, None) => 0
    _ => -2
  }
}
