type t = {
  timeBucket: AlertModal_Types.MacroTimeBucket.t,
  timeWindow: AlertModal_Types.MacroTimeWindow.t,
  relativeValueChange: float,
  absoluteValueChange: option<float>,
  emptyRelativeDiffAbsoluteValueChange: option<float>,
}

let getValueWithDefault = v =>
  v->Belt.Option.getWithDefault({
    timeBucket: #MACRO_TIME_BUCKET_5M,
    timeWindow: #MACRO_TIME_WINDOW_10M,
    relativeValueChange: 0.25,
    absoluteValueChange: Some(15.0),
    emptyRelativeDiffAbsoluteValueChange: Some(20.0),
  })

@react.component
let make = (~value, ~onChange) => {
  <>
    <MaterialUi.FormControl>
      <MaterialUi.InputLabel shrink=true htmlFor="">
        {React.string("time bucket")}
      </MaterialUi.InputLabel>
      <MaterialUi.Select
        onChange={(ev, _) => {
          let target = ev->ReactEvent.Form.target
          let newTimeBucket = target["value"]
          onChange({
            ...getValueWithDefault(value),
            timeBucket: newTimeBucket,
          })
        }}>
        {[#MACRO_TIME_BUCKET_5M]->Belt.Array.map(timeBucket =>
          <MaterialUi.MenuItem value={timeBucket->Obj.magic->MaterialUi.MenuItem.Value.string}>
            {AlertModal_Types.MacroTimeBucket.toDisplay(timeBucket)}
          </MaterialUi.MenuItem>
        )}
      </MaterialUi.Select>
    </MaterialUi.FormControl>
  </>
}
