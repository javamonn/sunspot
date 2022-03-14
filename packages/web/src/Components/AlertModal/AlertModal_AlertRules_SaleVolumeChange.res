@deriving(accessors)
type t = {
  timeBucket: AlertModal_Types.MacroTimeBucket.t,
  timeWindow: AlertModal_Types.MacroTimeWindow.t,
  relativeValueChange: option<float>,
  absoluteValueChange: option<int>,
  emptyRelativeDiffAbsoluteValueChange: option<int>,
  changeDirection: [
    | #CHANGE_ALL
    | #CHANGE_INCREASE
    | #CHANGE_DECREASE
  ],
}

let getValueWithDefault = v =>
  v->Belt.Option.getWithDefault({
    timeBucket: #MACRO_TIME_BUCKET_5M,
    timeWindow: #MACRO_TIME_WINDOW_10M,
    relativeValueChange: Some(0.25),
    absoluteValueChange: Some(15),
    emptyRelativeDiffAbsoluteValueChange: Some(20),
    changeDirection: #CHANGE_ALL,
  })

@react.component
let make = (~value, ~onChange) => {
  <>
    <InfoAlert
      text={React.string(
        "a collection sales volume change alert triggers when a change in the count of sale events bucketed by a time interval exceeds a relative percent threshold and/or an absolute count threshold.",
      )}
    />
    <div className={Cn.make(["flex", "flex-row", "mb-6", "mt-6", "space-x-6"])}>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1"]), ())}>
        <MaterialUi.TextField
          label={React.string("threshold percent change")}
          placeholder=""
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
          {React.string("minimum event count percent change")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1"]), ())}>
        <MaterialUi.TextField
          label={React.string("threshold absolute change")}
          _type="number"
          _InputLabelProps={{"shrink": true}}
          _InputProps={{
            "inputMode": "numeric",
          }}
          value={value
          ->getValueWithDefault
          ->absoluteValueChange
          ->Belt.Option.map(Belt.Int.toString)
          ->Belt.Option.getWithDefault("")
          ->MaterialUi.TextField.Value.string}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newAbsoluteValueChange = target["value"]
            let parsedNewAbosluteValueChange = switch Belt.Int.fromString(newAbsoluteValueChange) {
            | Some(newAbsoluteValueChange) => Some(newAbsoluteValueChange)
            | None if Js.String2.length(newAbsoluteValueChange) === 0 => None
            | _ => value->getValueWithDefault->absoluteValueChange
            }

            onChange({
              ...getValueWithDefault(value),
              absoluteValueChange: parsedNewAbosluteValueChange,
            })
          }}
        />
        <MaterialUi.FormHelperText>
          {React.string("minimum absolute event count change")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
    </div>
    <div className={Cn.make(["flex", "flex-row", "space-x-6"])}>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1"]), ())}>
        <MaterialUi.InputLabel shrink=true htmlFor="">
          {React.string("time bucket *")}
        </MaterialUi.InputLabel>
        <MaterialUi.Select
          value={value->getValueWithDefault->timeBucket->Obj.magic->MaterialUi.Select.Value.string}
          onChange={(ev, _) => {
            let target = ev->ReactEvent.Form.target
            let newTimeBucket = target["value"]
            onChange({
              ...getValueWithDefault(value),
              timeBucket: newTimeBucket,
            })
          }}>
          {[
            #MACRO_TIME_BUCKET_5M,
            #MACRO_TIME_BUCKET_15M,
            #MACRO_TIME_BUCKET_30M,
          ]->Belt.Array.map(timeBucket =>
            <MaterialUi.MenuItem value={timeBucket->Obj.magic->MaterialUi.MenuItem.Value.string}>
              {AlertModal_Types.MacroTimeBucket.toDisplay(timeBucket)}
            </MaterialUi.MenuItem>
          )}
        </MaterialUi.Select>
        <MaterialUi.FormHelperText>
          {React.string("the time interval to group and compare events")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1"]), ())}>
        <MaterialUi.InputLabel shrink=true htmlFor="">
          {React.string("time window *")}
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
          ]->Belt.Array.map(timeWindow => {
            let disabled = switch (value->getValueWithDefault->timeBucket, timeWindow) {
            | (#MACRO_TIME_BUCKET_15M, #MACRO_TIME_WINDOW_10M) => true
            | (#MACRO_TIME_BUCKET_30M, #MACRO_TIME_WINDOW_30M) => true
            | (#MACRO_TIME_BUCKET_30M, #MACRO_TIME_WINDOW_10M) => true
            | _ => false
            }
            <MaterialUi.MenuItem
              value={timeWindow->Obj.magic->MaterialUi.MenuItem.Value.string} disabled={disabled}>
              {AlertModal_Types.MacroTimeWindow.toDisplay(timeWindow)}
            </MaterialUi.MenuItem>
          })}
        </MaterialUi.Select>
        <MaterialUi.FormHelperText>
          {React.string("the sliding window of time to evaluate")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
    </div>
    <MaterialUi.FormControl
      classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["w-1/2", "mr-6", "mt-6"]), ())}>
      <MaterialUi.InputLabel shrink=true htmlFor="">
        {React.string("change type *")}
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
  </>
}
