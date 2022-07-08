exception MissingProvider

type t = {
  openCreateAlertModal: option<AlertModal.Value.t> => unit,
  openUpdateAlertModal: AlertModal.Value.t => unit,
}

let context = React.createContext({
  openCreateAlertModal: _ => raise(MissingProvider),
  openUpdateAlertModal: _ => raise(MissingProvider),
})
