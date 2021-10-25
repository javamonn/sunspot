@react.component
let make = (~onClick) => {
  <div className={Cn.make(["border-b", "border-solid", "border-black"])}>
    <MaterialUi.Button
      variant=#Text
      color=#Primary
      onClick={onClick}
      classes={MaterialUi.Button.Classes.make(
        ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
        (),
      )}>
      {React.string("connect wallet")}
    </MaterialUi.Button>
  </div>
}
