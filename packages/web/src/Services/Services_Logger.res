let log = (tag, message) => {
  Js.log2(tag, message)
}

let logWithData = (tag, message, data) => {
  Js.log3(tag, message, data)
}

let promiseError = (tag, message, e) => {
  Js.log3(tag, message, e)
}

let deccoError = (tag, message, e) => {
  Js.log3(tag, message, e)
}
