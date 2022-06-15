exception MissingProvider

type t = {
  openCreateAlertModal: unit => unit,
  openUpdateAlertModal: AlertModal.Value.t => unit,
}

let context = React.createContext({
  openCreateAlertModal: () => raise(MissingProvider),
  openUpdateAlertModal: _ => raise(MissingProvider),
})
