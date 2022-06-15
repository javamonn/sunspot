@react.component
let make = (~renderItems, ~icon, ~anchorOrigin, ~menuClasses) => {
  let (isOpen, setIsOpen) = React.useState(_ => false)
  let anchorRef = React.useRef(Js.Nullable.null)

  <>
    <MaterialUi.IconButton ref={anchorRef->ReactDOM.Ref.domRef} onClick={_ => setIsOpen(_ => true)} size=#Small>
      {icon}
    </MaterialUi.IconButton>
    <MaterialUi.Menu
      anchorEl=?{anchorRef.current->Js.Nullable.toOption->Belt.Option.map(Obj.magic)}
      anchorReference=#AnchorEl
      _open={isOpen}
      onClose={(_, _) => setIsOpen(_ => false)}
      anchorOrigin={anchorOrigin}
      classes={menuClasses}>
      {renderItems(~onClick=() => setIsOpen(_ => false))}
    </MaterialUi.Menu>
  </>
}
