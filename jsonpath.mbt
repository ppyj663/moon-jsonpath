pub fn query(json : Json, path_str : String) -> Result[Array[Json], String] {
  match parse(path_str) {
    Ok(path) => Ok(evaluate(json, path))
    Err(err) => Err(err)
  }
}
