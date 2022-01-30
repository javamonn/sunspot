type t = [
  | #listing
  | #sale
]

@react.component
let make = (~onChange, ~value: t) => {
  let handleChange = (ev, _) => {
    let target = ev->ReactEvent.Form.target
    target["value"]->Belt.Option.forEach((value: t) => onChange(value))
  }

  <MaterialUi.FormControl
    classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-8", "w-1/2"]), ())}>
    <MaterialUi.InputLabel shrink=true id="alert_rule_event" htmlFor="">
      {React.string("event")}
    </MaterialUi.InputLabel>
    <MaterialUi.Select
      labelId="AlertModal_action"
      value={(value :> string)->MaterialUi.Select.Value.string}
      fullWidth=true
      onChange={handleChange}>
      {[#listing, #sale]->Belt.Array.map((option_: t) => {
        let displayOption = (option_ :> string)

        <MaterialUi.MenuItem value={displayOption->MaterialUi.MenuItem.Value.string}>
          {displayOption->React.string}
        </MaterialUi.MenuItem>
      })}
    </MaterialUi.Select>
  </MaterialUi.FormControl>
}
