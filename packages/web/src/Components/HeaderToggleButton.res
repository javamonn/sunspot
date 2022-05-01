@react.component
let make = (~className=?, ~buttonClassName=?) => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()

  let handleClickToggleButton = pathname => {
    let _ = Externals.Next.Router.push(router, pathname)
  }

  let makeToggleButtonClasses = selected =>
    MaterialUi_Lab.ToggleButton.Classes.make(
      ~root=Cn.make([
        "px-8",
        "text-sm",
        "leading-none",
        "py-2",
        buttonClassName->Belt.Option.getWithDefault(""),
      ]),
      ~label=Cn.make([
        "lowercase",
        "font-bold",
        selected ? "text-darkPrimary" : "text-darkSecondary",
      ]),
      ~selected=Cn.make(["bg-darkBorder"]),
      (),
    )

  <MaterialUi_Lab.ToggleButtonGroup
    size=#Small
    exclusive={true}
    orientation=#Horizontal
    classes={MaterialUi_Lab.ToggleButtonGroup.Classes.make(
      ~root=Cn.make([className->Belt.Option.getWithDefault("")]),
      (),
    )}>
    <MaterialUi_Lab.ToggleButton
      onClick={_ => handleClickToggleButton("/alerts")}
      value={MaterialUi_Types.Any("left")}
      selected={router.pathname === "/alerts"}
      size=#Small
      style={ReactDOM.Style.make(~height="36px", ())}
      classes={makeToggleButtonClasses(router.pathname === "/alerts")}>
      {React.string("alerts")}
    </MaterialUi_Lab.ToggleButton>
    <MaterialUi_Lab.ToggleButton
      onClick={_ => handleClickToggleButton("/events")}
      selected={router.pathname === "/events"}
      value={MaterialUi_Types.Any("right")}
      size=#Small
      classes={makeToggleButtonClasses(router.pathname === "/events")}>
      {React.string("events")}
    </MaterialUi_Lab.ToggleButton>
  </MaterialUi_Lab.ToggleButtonGroup>
}
