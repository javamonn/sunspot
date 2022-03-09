type t = {
  timeWindow: AlertModal_Types.MacroTimeWindow.t,
  relativeValueChange: float,
  absoluteValueChange: option<float>,
}

let getValueWithDefault = v =>
  v->Belt.Option.getWithDefault({
    timeWindow: #MACRO_TIME_WINDOW_1H,
    relativeValueChange: 0.15,
    absoluteValueChange: Some(0.01)
  })

@react.component
let make = (~value, ~onChange) => {
  <>
    <MaterialUi.FormControl>
      <MaterialUi.InputLabel shrink=true htmlFor="">
        {React.string("time window")}
      </MaterialUi.InputLabel>
      <MaterialUi.Select
        onChange={(ev, _) => {
          let target = ev->ReactEvent.Form.target
          let newTimeWindow = target["value"]
          onChange({
            ...getValueWithDefault(value),
            timeWindow: newTimeWindow,
          })
        }}>
        {[#MACRO_TIME_WINDOW_5M]->Belt.Array.map(timeBucket =>
          <MaterialUi.MenuItem value={timeBucket->Obj.magic->MaterialUi.MenuItem.Value.string}>
            {AlertModal_Types.MacroTimeWindow.toDisplay(timeBucket)}
          </MaterialUi.MenuItem>
        )}
      </MaterialUi.Select>
    </MaterialUi.FormControl>
  </>
}
