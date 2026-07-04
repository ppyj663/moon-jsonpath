///|
fn main raise {
  let sample =
    #|{
    #|  "store": {
    #|    "book": [
    #|      { "title": "Sayings of the Century", "price": 8.95 },
    #|      { "title": "Sword of Honour", "price": 12.99 }
    #|    ],
    #|    "bicycle": { "color": "red", "price": 19.95 }
    #|  }
    #|}
  let json = @json.parse(sample)
  match @jsonpath.query(json, "$.store.book[0].title") {
    Ok(values) => {
      println("query: $.store.book[0].title")
      println("matches: \{values.length()}")
      for value in values {
        println(value.stringify())
      }
    }
    Err(message) => println("error: \{message}")
  }
}
