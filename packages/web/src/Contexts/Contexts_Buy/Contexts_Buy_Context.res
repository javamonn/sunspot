type t = {
  isBuyModalOpen: bool,
  isQuickbuyTxPending: bool,
  setIsQuickbuyTxPending: bool => unit,
}

let context = React.createContext({
  isBuyModalOpen: false,
  isQuickbuyTxPending: false,
  setIsQuickbuyTxPending: _ => (),
})

