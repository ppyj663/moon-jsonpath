pub fn evaluate(json : Json, path : JSONPath) -> Array[Json] {
  let mut current = [json]
  for i = 0; i < path.length(); i = i + 1 {
    let segment = path[i]
    let next = []
    for j = 0; j < current.length(); j = j + 1 {
      let node = current[j]
      match segment {
        Root => next.push(node)
        Child(name) => match node { Object(obj) => match obj.get(name) { Some(val) => next.push(val); None => () }; _ => () }
        Index(idx) => match node { Array(arr) => if idx >= 0 && idx < arr.length() { next.push(arr[idx]) }; _ => () }
        _ => ()
      }
    }
    current = next
  }
  current
}
