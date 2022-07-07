@deriving(accessors)
type t = {
  timeWindow: option<AlertModal_Types.MacroTimeWindow.t>,
  relativeValueChange: option<float>,
  absoluteValueChange: option<string>,
  changeDirection: option<[
    | #CHANGE_ALL
    | #CHANGE_INCREASE
    | #CHANGE_DECREASE
  ]>,
}

let getValueWithDefault = v =>
  v->Belt.Option.getWithDefault({
    timeWindow: None,
    relativeValueChange: None,
    absoluteValueChange: None,
    changeDirection: None,
  })

@react.component
let make = (~value, ~onChange) => {
  <div className={Cn.make(["flex", "flex-col", "flex-1"])}>
    <div className={Cn.make(["flex", "flex-row", "mb-6", "mt-6", "space-x-6"])}>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1"]), ())}>
        <MaterialUi.TextField
          label={React.string("percent change")}
          placeholder="15"
          _type="number"
          _InputLabelProps={{"shrink": true}}
          _InputProps={{
            "inputMode": "numeric",
            "endAdornment": <MaterialUi.InputAdornment position=#End>
              {React.string(`%`)}
            </MaterialUi.InputAdornment>,
          }}
          value={value
          ->getValueWithDefault
          ->relativeValueChange
          ->Belt.Option.map(Services.Format.percent(~includeSymbol=false))
          ->Belt.Option.getWithDefault("")
          ->MaterialUi.TextField.Value.string}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]

            switch Belt.Float.fromString(newValue) {
            | Some(newValue) =>
              onChange({
                ...getValueWithDefault(value),
                relativeValueChange: Some(newValue /. 100.0),
              })
            | None if Js.String2.length(newValue) === 0 =>
              onChange({
                ...getValueWithDefault(value),
                relativeValueChange: None,
              })
            | _ => ()
            }
          }}
        />
        <MaterialUi.FormHelperText>
          {React.string("minimum floor price percent change")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1"]), ())}>
        <MaterialUi.InputLabel shrink=true htmlFor="">
          {React.string("change type")}
        </MaterialUi.InputLabel>
        <MaterialUi.Select
          value={value
          ->getValueWithDefault
          ->changeDirection
          ->Obj.magic
          ->MaterialUi.Select.Value.string}
          onChange={(ev, _) => {
            let target = ev->ReactEvent.Form.target
            let newChangeDirection = target["value"]
            onChange({
              ...getValueWithDefault(value),
              changeDirection: newChangeDirection,
            })
          }}>
          {[#CHANGE_ALL, #CHANGE_INCREASE, #CHANGE_DECREASE]->Belt.Array.map(changeType => {
            <MaterialUi.MenuItem value={changeType->Obj.magic->MaterialUi.MenuItem.Value.string}>
              {switch changeType {
              | #CHANGE_ALL => "all"
              | #CHANGE_INCREASE => "increase"
              | #CHANGE_DECREASE => "decrease"
              }}
            </MaterialUi.MenuItem>
          })}
        </MaterialUi.Select>
        <MaterialUi.FormHelperText>
          {React.string("the direction of change to consider")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
    </div>
    <MaterialUi.FormControl
      classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["w-1/2", "pr-4", "mt-6"]), ())}>
      <MaterialUi.InputLabel shrink=true htmlFor="">
        {React.string("time window")}
      </MaterialUi.InputLabel>
      <MaterialUi.Select
        value={value->getValueWithDefault->timeWindow->Obj.magic->MaterialUi.Select.Value.string}
        onChange={(ev, _) => {
          let target = ev->ReactEvent.Form.target
          let newTimeWindow = target["value"]
          onChange({
            ...getValueWithDefault(value),
            timeWindow: newTimeWindow,
          })
        }}>
        {[
          #MACRO_TIME_WINDOW_10M,
          #MACRO_TIME_WINDOW_30M,
          #MACRO_TIME_WINDOW_1H,
          #MACRO_TIME_WINDOW_12H,
          #MACRO_TIME_WINDOW_24H,
        ]->Belt.Array.map(timeWindow => {
          <MaterialUi.MenuItem value={timeWindow->Obj.magic->MaterialUi.MenuItem.Value.string}>
            {AlertModal_Types.MacroTimeWindow.toDisplay(timeWindow)}
          </MaterialUi.MenuItem>
        })}
      </MaterialUi.Select>
      <MaterialUi.FormHelperText>
        {React.string("the sliding window of time to evaluate")}
      </MaterialUi.FormHelperText>
    </MaterialUi.FormControl>
  </div>
}
