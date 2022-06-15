@react.component
let make = () => {
  <MaterialUi.Button
    variant=#Outlined
    classes={MaterialUi.Button.Classes.make(~root=Cn.make(["py-0"]), ~label=Cn.make(["py-0"]), ())}>
    <div
      style={ReactDOM.Style.make(~width="80px", ~height="36px", ())}
      className={Cn.make(["px-3", "flex", "items-center"])}>
      <MaterialUi.LinearProgress
        color={#Secondary}
        variant={#Indeterminate}
        classes={MaterialUi.LinearProgress.Classes.make(~root=Cn.make(["flex-1"]), ())}
      />
    </div>
  </MaterialUi.Button>
}
