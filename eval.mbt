///|
pub fn evaluate(json : Json, path : JSONPath) -> Array[Json] {
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
        Index(idx) =>
          match node {
            Array(arr) =>
              if idx >= 0 && idx < arr.length() {
                next.push(arr[idx])
              }
            _ => ()
          }
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
        Descendant(name) => find_descendants(node, name, next)
      }
    }
    current = next
  }
  current
}

///|
fn find_descendants(node : Json, name : String, acc : Array[Json]) -> Unit {
  match node {
    Object(obj) => {
      match obj.get(name) {
        Some(val) => acc.push(val)
        None => ()
      }
      for _, val in obj {
        find_descendants(val, name, acc)
      }
    }
    Array(arr) =>
      for val in arr {
        find_descendants(val, name, acc)
      }
    _ => ()
  }
}
