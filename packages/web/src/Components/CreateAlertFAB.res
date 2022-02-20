@react.component
let make = (~className=?, ~onClick) =>
  <MaterialUi.Fab
    color=#Primary
    classes={MaterialUi.Fab.Classes.make(
      ~root=Cn.make([className->Belt.Option.getWithDefault("")]),
      (),
    )}
    onClick={_ => {
      let _ = onClick()
    }}>
    <Externals.MaterialUi_Icons.Add />
  </MaterialUi.Fab>
