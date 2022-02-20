@react.component
let make = (~onClick) => {
  <MaterialUi.Button
    variant=#Outlined
    color=#Primary
    onClick={onClick}
    classes={MaterialUi.Button.Classes.make(
      ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
      (),
    )}>
    {React.string("connect")}
  </MaterialUi.Button>
}
