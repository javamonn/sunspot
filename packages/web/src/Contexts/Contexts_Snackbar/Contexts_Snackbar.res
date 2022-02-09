type type_ =
  | TypeSuccess
  | TypeError
  | TypeWarning
type snackbar = {message: React.element, type_: type_, duration: option<int>}
type snackbarState =
  | Closed
  | Closing(snackbar)
  | Open(snackbar)

type openSnackbar = (~message: React.element, ~type_: type_, ~duration: int=?, unit) => unit

type t = {openSnackbar: openSnackbar}

let context = React.createContext({
  openSnackbar: (~message, ~type_, ~duration=?, ()) => (),
})

module ContextProvider = {
  include React.Context

  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(context)
}

@react.component
let make = (~children) => {
  let (snackbarState, setSnackbarState) = React.useState(_ => Closed)

  let handleOpenSnackbar = (~message, ~type_, ~duration=?, ()) =>
    setSnackbarState(_ => Open({message: message, type_: type_, duration: duration}))
  let handleCloseSnackbar = () =>
    setSnackbarState(snackbarState =>
      switch snackbarState {
      | Open(s) => Closing(s)
      | s => s
      }
    )
  let handleExitedSnackbar = () => setSnackbarState(_ => Closed)

  <ContextProvider
    value={
      openSnackbar: handleOpenSnackbar,
    }>
    {children}
    <MaterialUi.Snackbar
      autoHideDuration=?{switch snackbarState {
      | Open({duration: Some(duration)}) | Closing({duration: Some(duration)}) =>
        duration->MaterialUi_Types.Number.int->Js.Option.some
      | _ => None
      }}
      _open={switch snackbarState {
      | Open(_) => true
      | Closed | Closing(_) => false
      }}
      onClose={(_, _) => handleCloseSnackbar()}
      onExited={_ => handleExitedSnackbar()}
      anchorOrigin={MaterialUi.Snackbar.AnchorOrigin.make(
        ~horizontal=MaterialUi.Snackbar.Horizontal.right,
        ~vertical=MaterialUi.Snackbar.Vertical.bottom,
        (),
      )}>
      {switch snackbarState {
      | Open({message, type_}) | Closing({message, type_}) =>
        let alertType = switch type_ {
        | TypeError => #Error
        | TypeSuccess => #Success
        | TypeWarning => #Warning
        }
        <MaterialUi_Lab.Alert
          color={alertType}
          severity={alertType}
          classes={MaterialUi_Lab.Alert.Classes.make(
            ~root=Cn.make(["flex", "flex-row", "items-center"]),
            ~message=Cn.make(["w-96", "block"]),
            (),
          )}>
          {message}
        </MaterialUi_Lab.Alert>
      | Closed => React.null
      }}
    </MaterialUi.Snackbar>
  </ContextProvider>
}
