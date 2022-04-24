exception MissingProvider

type t = {openDialog: option<React.element> => Js.Promise.t<option<[#TELESCOPE | #OBSERVATORY]>>}

let context = React.createContext({
  openDialog: _ => Js.Promise.reject(MissingProvider),
})
