type t = [
  | #LISTING
  | #SALE
  | #FLOOR_PRICE_CHANGE
  | #SALE_VOLUME_CHANGE
]

let toDisplay = v =>
  switch v {
  | #LISTING => ("listing", "a token is listed for sale")
  | #SALE => ("sale", "a token is sold")
  | #FLOOR_PRICE_CHANGE => (
      "collection floor price change",
      "the collection floor price (most recent 15 events) changes",
    )
  | #SALE_VOLUME_CHANGE => (
      "collection sales volume change",
      "the count of token sale events to occur within a time interval changes",
    )
  }

@react.component
let make = (~onChange, ~value: t) => {
  let handleChange = (ev, _) => {
    let target = ev->ReactEvent.Form.target
    target["value"]->Belt.Option.forEach((value: t) => onChange(value))
  }

  <MaterialUi.FormControl
    classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-8", "w-full"]), ())}>
    <MaterialUi.InputLabel shrink=true htmlFor=""> {React.string("event")} </MaterialUi.InputLabel>
    <MaterialUi.Select
      value={(value :> string)->MaterialUi.Select.Value.string}
      fullWidth=true
      onChange={handleChange}>
      {[#LISTING, #SALE, #FLOOR_PRICE_CHANGE, #SALE_VOLUME_CHANGE]->Belt.Array.map((option_: t) => {
        let (primary, secondary) = toDisplay(option_)
        <MaterialUi.MenuItem value={option_->Obj.magic->MaterialUi.MenuItem.Value.string}>
          <MaterialUi.ListItemText
            primary={React.string(primary)} secondary={React.string(secondary)}
          />
        </MaterialUi.MenuItem>
      })}
    </MaterialUi.Select>
  </MaterialUi.FormControl>
}
