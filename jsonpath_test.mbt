///|
fn sample_json() -> Json raise {
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
  @json.parse(json_str)
}

///|
test "jsonpath query core syntax" {
  let json = sample_json()

  match query(json, "$") {
    Ok(res) => if res.length() != 1 { abort("root failed") }
    Err(_) => abort("root failed err")
  }

  match query(json, "$.store.bicycle.color") {
    Ok(res) => {
      if res.length() != 1 {
        abort("child length failed")
      }
      if res[0].stringify() != "\"red\"" {
        abort("child content failed")
      }
    }
    Err(_) => abort("child failed err")
  }

  match query(json, "$.store.book[1].author") {
    Ok(res) => {
      if res.length() != 1 {
        abort("array length failed")
      }
      if res[0].stringify() != "\"Evelyn Waugh\"" {
        abort("array content failed")
      }
    }
    Err(_) => abort("array failed err")
  }

  match query(json, "$.store.bicycle.*") {
    Ok(res) => if res.length() != 2 { abort("wildcard length failed") }
    Err(_) => abort("wildcard failed err")
  }

  match query(json, "$.store.book[*].author") {
    Ok(res) => if res.length() != 4 { abort("wildcard array failed") }
    Err(_) => abort("wildcard array failed err")
  }

  match query(json, "$..price") {
    Ok(res) => if res.length() != 5 { abort("descendant failed") }
    Err(_) => abort("descendant err")
  }

  match query(json, "$['store']['bicycle']['color']") {
    Ok(res) => {
      if res.length() != 1 {
        abort("bracket length failed")
      }
      if res[0].stringify() != "\"red\"" {
        abort("bracket content failed")
      }
    }
    Err(_) => abort("bracket err")
  }
}

///|
test "jsonpath missing and invalid queries" {
  let json = sample_json()

  match query(json, "$.store.missing") {
    Ok(res) => if res.length() != 0 { abort("missing field should not match") }
    Err(_) => abort("missing field should not raise")
  }

  match query(json, "$.store.book[99]") {
    Ok(res) =>
      if res.length() != 0 {
        abort("out-of-range index should not match")
      }
    Err(_) => abort("out-of-range index should not raise")
  }

  match query(json, "store.book") {
    Ok(_) => abort("path without root should fail")
    Err(message) =>
      if message != "JSONPath must start with '$'" {
        abort("unexpected missing-root error")
      }
  }

  match query(json, "$.") {
    Ok(_) => abort("trailing dot should fail")
    Err(message) =>
      if message != "Expected identifier after '.'" {
        abort("unexpected trailing-dot error")
      }
  }

  match query(json, "$['store'") {
    Ok(_) => abort("unterminated bracket should fail")
    Err(message) =>
      if message != "Expected ']' after string literal" {
        abort("unexpected unterminated-bracket error")
      }
  }
}
