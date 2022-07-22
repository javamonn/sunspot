@deriving(accessors)
type t = {
  modifier: string,
  value: option<string>,
}
let makeRule = (~modifier, ~value) => {
  modifier: modifier,
  value: value,
}

@react.component
let make = (~ruleLabel="price", ~value=?, ~onChange, ~accordionExpanded) => {
  <div className={Cn.make(["flex", "flex-col"])}>
    <InfoAlert
      className={Cn.make(["mb-6"])}
      text={React.string(
        "value can be a token price (e.g. \"1.4\") or a dynamic expression involving the collection floor price at the time of the event (e.g. \"floorPrice + .05\").",
      )}
    />
    <div className={Cn.make(["flex", "flex-row", "flex-1"])}>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root={Cn.make(["flex-1"])}, ())}>
        <MaterialUi.InputLabel shrink=true id={`CreateAlertModal_price_rule`} htmlFor="">
          {React.string("rule")}
        </MaterialUi.InputLabel>
        <MaterialUi.Select
          labelId={`CreateAlertModal_price_rule`}
          value={MaterialUi.Select.Value.string(ruleLabel)}
          disabled=true
          fullWidth=true>
          <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string(ruleLabel)}>
            {React.string(ruleLabel)}
          </MaterialUi.MenuItem>
        </MaterialUi.Select>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1", "ml-4"]), ())}>
        <MaterialUi.InputLabel shrink=true id={`CreateAlertModal_price_modifier`} htmlFor="">
          {React.string("modifier")}
        </MaterialUi.InputLabel>
        <MaterialUi.Select
          labelId="CreateAlertModal_rule"
          value={value
          ->Belt.Option.map(v => v->modifier)
          ->Belt.Option.getWithDefault("")
          ->MaterialUi.Select.Value.string}
          fullWidth=true
          onChange={(ev, _) => {
            let target = ev->ReactEvent.Form.target
            let newModifier = target["value"]
            switch value {
            | Some(value) => onChange(Some({...value, modifier: newModifier}))
            | None => onChange(Some({value: None, modifier: newModifier}))
            }
          }}>
          <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("<")}>
            {React.string("<")}
          </MaterialUi.MenuItem>
          <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string(">")}>
            {React.string(">")}
          </MaterialUi.MenuItem>
        </MaterialUi.Select>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1", "ml-4"]), ())}>
        <MaterialUi.TextField
          label={React.string("value")}
          placeholder="0.0"
          _type="text"
          _InputLabelProps={{"shrink": true}}
          _InputProps={{
            "inputMode": "text",
          }}
          value=?{value
          ->Belt.Option.flatMap(v => v.value)
          ->Belt.Option.map(MaterialUi.TextField.Value.string)}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]
            switch (newValue, value) {
            | (None, Some({modifier: ""}))
            | (Some(""), Some({modifier: ""}))
            | (None, None)
            | (Some(""), None) =>
              onChange(None)
            | (_, Some(v)) => onChange(Some({...v, value: newValue}))
            | (Some(_), None) => onChange(Some({modifier: "", value: newValue}))
            }
          }}
        />
      </MaterialUi.FormControl>
    </div>
  </div>
}

let make = React.memoCustomCompareProps(make, (prevProps, nextProps) =>
  !nextProps["accordionExpanded"] ||
  Belt.Option.eq(prevProps["value"], nextProps["value"], (a, b) =>
    modifier(a) == modifier(b) && Belt.Option.eq(value(a), value(b), (a, b) => a == b)
  )
)
