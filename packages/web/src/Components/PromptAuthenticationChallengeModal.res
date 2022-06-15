@react.component
let make = (~isOpen, ~onClose) => {
  <MaterialUi.Dialog _open={isOpen} onClose={(_, _) => onClose(false)}>
    <MaterialUi.DialogTitle> {React.string("sign message to sign in")} </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(
        ~root=Cn.make(["font-mono", "whitespace-pre-wrap"]),
        (),
      )}>
      {React.string(
        "click \"sign in\" to authenticate by signing a message.\n\nsunspot uses this cryptographic signature in place of a password to verify that you are the owner of the connected ethereum address.",
      )}
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions>
      <MaterialUi.Button
        onClick={_ => onClose(false)}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["mr-2"]),
          ~label=Cn.make(["lowercase"]),
          (),
        )}>
        {React.string("cancel")}
      </MaterialUi.Button>
      <MaterialUi.Button
        variant=#Contained
        color=#Primary
        onClick={_ => onClose(true)}
        classes={MaterialUi.Button.Classes.make(~label=Cn.make(["lowercase"]), ())}>
        {React.string("sign in")}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
