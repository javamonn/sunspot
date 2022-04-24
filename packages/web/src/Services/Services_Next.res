let parseQuery = path => {
  let queryIndex = Js.String2.indexOf(path, "?")
  if queryIndex !== -1 {
    try {
      Js.String2.substringToEnd(~from=queryIndex, path)
      ->Externals.Webapi.URLSearchParams.make
      ->Js.Option.some
    } catch {
    | _ => None
    }
  } else {
    None
  }
}

