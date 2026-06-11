test "jsonpath query" {
  let json_str =
    #|{
    #|  "store": {
    #|    "book": [
    #|      { "category": "reference", "author": "Nigel Rees", "title": "Sayings of the Century", "price": 8.95 },
    #|      { "category": "fiction", "author": "Evelyn Waugh", "title": "Sword of Honour", "price": 12.99 },
    #|      { "category": "fiction", "author": "Herman Melville", "title": "Moby Dick", "isbn": "0-553-21311-3", "price": 8.99 },
    #|      { "category": "fiction", "author": "J. R. R. Tolkien", "title": "The Lord of the Rings", "isbn": "0-395-19395-8", "price": 22.99 }
    #|    ],
    #|    "bicycle": {
    #|      "color": "red",
    #|      "price": 19.95
    #|    }
    #|  }
    #|}
  let json = @json.parse!(json_str)

  // Test root
  match query(json, "$") {
    Ok(res) => if res.length() != 1 { abort("root failed") }
    Err(_) => abort("root failed err")
  }

  // Test child access
  match query(json, "$.store.bicycle.color") {
    Ok(res) => {
      if res.length() != 1 { abort("child length failed") }
      if res[0].stringify() != "\"red\"" { abort("child content failed") }
    }
    Err(_) => abort("child failed err")
  }

  // Test array index
  match query(json, "$.store.book[1].author") {
    Ok(res) => {
      if res.length() != 1 { abort("array length failed") }
      if res[0].stringify() != "\"Evelyn Waugh\"" { abort("array content failed") }
    }
    Err(_) => abort("array failed err")
  }

  // Test wildcard object
  match query(json, "$.store.bicycle.*") {
    Ok(res) => {
      if res.length() != 2 { abort("wildcard length failed") }
    }
    Err(_) => abort("wildcard failed err")
  }

  // Test wildcard array
  match query(json, "$.store.book[*].author") {
    Ok(res) => {
      if res.length() != 4 { abort("wildcard array failed") }
    }
    Err(_) => abort("wildcard array failed err")
  }

  // Test descendant
  match query(json, "$..price") {
    Ok(res) => {
      if res.length() != 5 { abort("descendant failed") }
    }
    Err(_) => abort("descendant err")
  }

  // Test bracket notation
  match query(json, "$['store']['bicycle']['color']") {
    Ok(res) => {
      if res.length() != 1 { abort("bracket length failed") }
      if res[0].stringify() != "\"red\"" { abort("bracket content failed") }
    }
    Err(_) => abort("bracket err")
  }
}
