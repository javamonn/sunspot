@react.component
let make = () => {
  let (isOpen, setIsOpen) = React.useState(_ => false)
  let anchorRef = React.useRef(Js.Nullable.null)

  <>
    <MaterialUi.IconButton
      classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["ml-4"]), ())}
      ref={anchorRef->ReactDOM.Ref.domRef}
      onClick={_ => setIsOpen(_ => true)}>
      <Externals.MaterialUi_Icons.HelpOutline />
    </MaterialUi.IconButton>
    <MaterialUi.Popover
      _open={isOpen}
      anchorEl=?{anchorRef.current->Js.Nullable.toOption->Belt.Option.map(Obj.magic)}
      anchorReference=#AnchorEl
      onClose={_ => setIsOpen(_ => false)}
      anchorOrigin={
        open MaterialUi.Popover
        AnchorOrigin.make(
          ~horizontal=Horizontal.enum(Horizontal_enum.right),
          ~vertical=Vertical.enum(Vertical_enum.bottom),
          (),
        )
      }
      transformOrigin={
        open MaterialUi.Popover
        TransformOrigin.make(
          ~horizontal=Horizontal.enum(Horizontal_enum.right),
          ~vertical=Vertical.enum(Vertical_enum.top),
          (),
        )
      }>
      <div
        style={ReactDOM.Style.make(~width="42rem", ())} className={Cn.make(["p-6", "bg-gray-100"])}>
        <MaterialUi.Typography
          variant=#Body1
          color=#Primary
          classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-6"]), ())}>
          {React.string("sunspot alerts you when events occur within eth nft secondary markets.")}
        </MaterialUi.Typography>
        <MaterialUi.Typography
          variant=#Body1
          color=#Primary
          classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-6"]), ())}>
          {React.string(
            "alert rules are defined over collections, event type, and optional price filter. when an event satisfying an alert rule occurs, a notification will be delivered notifying you in near real-time.",
          )}
        </MaterialUi.Typography>
        <MaterialUi.Typography
          variant=#Body1
          color=#Primary
          classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-6"]), ())}>
          {React.string(
            "sunspot is a work in progress. in the near future, more complex event types (e.g. floor price movement), filters (e.g. rarity-based), and alert destinations (e.g. sms) will be supported.",
          )}
        </MaterialUi.Typography>
        <MaterialUi.Typography
          variant=#Body1
          color=#Primary
          classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-6"]), ())}>
          {React.string(
            "sunspot is user supported. if you find it useful, please consider donating: 0x9Bf2A698A34b54D58d036277133d6a8205Bd5d5a",
          )}
        </MaterialUi.Typography>
        <MaterialUi.Typography variant=#Body1 color=#Primary>
          <ul>
            <li>
              {React.string("> get involved on ")} <a href="https://discord.gg/y3wcMgagsF" className={Cn.make(["underline"])}> {React.string("discord")} </a> {React.string(".")}
            </li>
            <li>
              {React.string("> view the source code on ")} <a href="https://github.com/javamonn/sunspot" className={Cn.make(["underline"])}> {React.string("github")} </a> {React.string(".")}
            </li>
          </ul>
        </MaterialUi.Typography>
      </div>
    </MaterialUi.Popover>
  </>
}
