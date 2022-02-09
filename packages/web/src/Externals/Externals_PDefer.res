@deriving(accessors)
type t<'a> = {
  resolve: 'a => unit,
  promise: Js.Promise.t<'a>,
  reject: Js.Exn.t => unit,
}

@module("p-defer") external make: unit => t<'a> = "default"
