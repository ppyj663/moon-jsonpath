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
test "jsonpath slicing and negative indices" {
  let json = sample_json()

  // Slicing: [1:3] (should return elements at index 1 and 2)
  match query(json, "$.store.book[1:3]") {
    Ok(res) => {
      if res.length() != 2 {
        abort("slice length failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"Evelyn Waugh\",\"title\":\"Sword of Honour\",\"price\":12.99}" {
        abort("slice element 0 failed: " + res[0].stringify())
      }
      if res[1].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"Herman Melville\",\"title\":\"Moby Dick\",\"isbn\":\"0-553-21311-3\",\"price\":8.99}" {
        abort("slice element 1 failed: " + res[1].stringify())
      }
    }
    Err(err) => abort("slice failed: " + err)
  }

  // Slicing with default end: [2:] (elements at index 2 and 3)
  match query(json, "$.store.book[2:]") {
    Ok(res) => if res.length() != 2 { abort("slice default end failed") }
    Err(_) => abort("slice default end failed")
  }

  // Slicing with default start: [:2] (elements at index 0 and 1)
  match query(json, "$.store.book[:2]") {
    Ok(res) => if res.length() != 2 { abort("slice default start failed") }
    Err(_) => abort("slice default start failed")
  }

  // Slicing with step: [::2] (elements at index 0 and 2)
  match query(json, "$.store.book[::2]") {
    Ok(res) => {
      if res.length() != 2 {
        abort("slice step failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"reference\",\"author\":\"Nigel Rees\",\"title\":\"Sayings of the Century\",\"price\":8.95}" {
        abort("slice step element 0 failed")
      }
    }
    Err(_) => abort("slice step failed")
  }

  // Slicing with negative step: [3:0:-2] (elements at index 3 and 1)
  match query(json, "$.store.book[3:0:-2]") {
    Ok(res) => {
      if res.length() != 2 {
        abort("slice negative step failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"J. R. R. Tolkien\",\"title\":\"The Lord of the Rings\",\"isbn\":\"0-395-19395-8\",\"price\":22.99}" {
        abort("slice negative step element 0 failed: " + res[0].stringify())
      }
    }
    Err(err) => abort("slice negative step failed: " + err)
  }

  // Negative index: [-1] (should return last book)
  match query(json, "$.store.book[-1]") {
    Ok(res) => {
      if res.length() != 1 {
        abort("negative index length failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"J. R. R. Tolkien\",\"title\":\"The Lord of the Rings\",\"isbn\":\"0-395-19395-8\",\"price\":22.99}" {
        abort("negative index content failed: " + res[0].stringify())
      }
    }
    Err(_) => abort("negative index failed")
  }
}

///|
test "jsonpath union selectors" {
  let json = sample_json()

  // Index union: [0, 2] (books at index 0 and 2)
  match query(json, "$.store.book[0, 2]") {
    Ok(res) => {
      if res.length() != 2 {
        abort("index union failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"reference\",\"author\":\"Nigel Rees\",\"title\":\"Sayings of the Century\",\"price\":8.95}" {
        abort("index union 0 failed")
      }
      if res[1].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"Herman Melville\",\"title\":\"Moby Dick\",\"isbn\":\"0-553-21311-3\",\"price\":8.99}" {
        abort("index union 1 failed")
      }
    }
    Err(_) => abort("index union failed")
  }

  // Field name union: ['title', 'price']
  match query(json, "$.store.book[0]['title', 'price']") {
    Ok(res) => {
      if res.length() != 2 {
        abort("field union failed")
      }
      if res[0].stringify() != "\"Sayings of the Century\"" {
        abort("field union 0 failed: " + res[0].stringify())
      }
      if res[1].stringify() != "8.95" {
        abort("field union 1 failed: " + res[1].stringify())
      }
    }
    Err(_) => abort("field union failed")
  }
}

///|
test "jsonpath filter selectors" {
  let json = sample_json()

  // Filter existence: books with isbn
  match query(json, "$.store.book[?(@.isbn)]") {
    Ok(res) => {
      if res.length() != 2 {
        abort("filter existence failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"Herman Melville\",\"title\":\"Moby Dick\",\"isbn\":\"0-553-21311-3\",\"price\":8.99}" {
        abort("filter existence content failed")
      }
    }
    Err(err) => abort("filter existence failed: " + err)
  }

  // Filter comparison: books with price < 10
  match query(json, "$.store.book[?(@.price < 10)]") {
    Ok(res) => {
      if res.length() != 2 {
        abort("filter comparison < failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"reference\",\"author\":\"Nigel Rees\",\"title\":\"Sayings of the Century\",\"price\":8.95}" {
        abort("filter comparison 0 failed")
      }
      if res[1].stringify() !=
        "{\"category\":\"fiction\",\"author\":\"Herman Melville\",\"title\":\"Moby Dick\",\"isbn\":\"0-553-21311-3\",\"price\":8.99}" {
        abort("filter comparison 1 failed")
      }
    }
    Err(err) => {
      println("query error: " + err)
      abort("filter comparison < failed")
    }
  }

  // Compound filter logic: price < 10 && category == 'reference'
  match
    query(json, "$.store.book[?(@.price < 10 && @.category == 'reference')]") {
    Ok(res) => {
      if res.length() != 1 {
        abort("compound filter failed")
      }
      if res[0].stringify() !=
        "{\"category\":\"reference\",\"author\":\"Nigel Rees\",\"title\":\"Sayings of the Century\",\"price\":8.95}" {
        abort("compound filter content failed")
      }
    }
    Err(err) => abort("compound filter failed: " + err)
  }

  // Filter with logical OR: price < 10 || price > 20
  match query(json, "$.store.book[?(@.price < 10 || @.price > 20)]") {
    Ok(res) => if res.length() != 3 { abort("logical OR filter failed") }
    Err(_) => abort("logical OR filter failed")
  }

  // Logical NOT: books without isbn
  match query(json, "$.store.book[?(!@.isbn)]") {
    Ok(res) =>
      if res.length() != 2 {
        abort("logical NOT filter failed: " + res.length().to_string())
      }
    Err(_) => abort("logical NOT filter failed")
  }
}

///|
test "jsonpath string escape handling" {
  // Test double/single quotes and unicode escape sequences inside name selectors
  let input_json =
    #|{
    #|  "escaped\nkey": 42,
    #|  "unicode\u0041key": 100
    #|}
  let json = @json.parse(input_json)

  match query(json, "$['escaped\\nkey']") {
    Ok(res) => {
      if res.length() != 1 {
        abort("escaped key failed")
      }
      if res[0].stringify() != "42" {
        abort("escaped key content failed")
      }
    }
    Err(err) => abort("escaped key failed: " + err)
  }

  match query(json, "$['unicode\\u0041key']") {
    Ok(res) => {
      if res.length() != 1 {
        abort("unicode key failed")
      }
      if res[0].stringify() != "100" {
        abort("unicode key content failed")
      }
    }
    Err(err) => abort("unicode key failed: " + err)
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
      if message != "Expected path starting with '$'" {
        abort("unexpected missing-root error: " + message)
      }
  }

  match query(json, "$.") {
    Ok(_) => abort("trailing dot should fail")
    Err(message) =>
      if message != "Expected identifier after '.' or '..'" {
        abort("unexpected trailing-dot error: " + message)
      }
  }

  match query(json, "$['store'") {
    Ok(_) => abort("unterminated bracket should fail")
    Err(message) =>
      if message != "Expected ',' or ']' inside bracket selector" {
        abort("unexpected unterminated-bracket error: " + message)
      }
  }
}

///|
test "jsonpath performance verification" {
  let json = sample_json()
  // Run query 1000 times as a simple benchmark performance verification
  let path = "$.store.book[?(@.price < 15)].title"
  for i = 0; i < 1000; i = i + 1 {
    let _ = query(json, path)
  }
  println(
    "Performance verification run completed successfully for 1000 iterations.",
  )
}
