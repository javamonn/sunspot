type t = {
  isOpen: bool,
  isQuickbuyTxPending: bool,
  setIsQuickbuyTxPending: bool => unit,
}

let context = React.createContext({
  isOpen: false,
  isQuickbuyTxPending: false,
  setIsQuickbuyTxPending: _ => (),
})

