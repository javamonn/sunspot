module Value = {
  @deriving(accessors)
  type t = {
    modifier: string,
    value: option<string>,
  }

  let make = (~modifier, ~value) => {
    modifier: modifier,
    value: value,
  }
}

@react.component
let make = (~value=?, ~onChange, ~accordionExpanded) => {
  <div className={Cn.make(["flex", "flex-row", "flex-1"])}>
    <MaterialUi.FormControl
      classes={MaterialUi.FormControl.Classes.make(~root={Cn.make(["flex-1"])}, ())}>
      <MaterialUi.InputLabel shrink=true htmlFor=""> {React.string("rule")} </MaterialUi.InputLabel>
      <MaterialUi.Select
        value={MaterialUi.Select.Value.string("quantity")} disabled=true fullWidth=true>
        <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("quantity")}>
          {React.string("quantity")}
        </MaterialUi.MenuItem>
      </MaterialUi.Select>
    </MaterialUi.FormControl>
    <MaterialUi.FormControl
      classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1", "ml-4"]), ())}>
      <MaterialUi.InputLabel shrink=true htmlFor="">
        {React.string("modifier")}
      </MaterialUi.InputLabel>
      <MaterialUi.Select
        value={value
        ->Belt.Option.map(v => v->Value.modifier)
        ->Belt.Option.getWithDefault("")
        ->MaterialUi.Select.Value.string}
        fullWidth=true
        onChange={(ev, _) => {
          let target = ev->ReactEvent.Form.target
          let newModifier = target["value"]
          switch value {
          | Some(value) => onChange(Some({...value, Value.modifier: newModifier}))
          | None => onChange(Some({value: None, Value.modifier: newModifier}))
          }
        }}>
        <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("=")}>
          {React.string("=")}
        </MaterialUi.MenuItem>
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
        placeholder="1"
        _type="number"
        _InputLabelProps={{"shrink": true}}
        _InputProps={{
          "inputMode": "numeric",
        }}
        inputProps={{
          "step": "1",
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
          | (_, Some(v)) => onChange(Some({...v, Value.value: newValue}))
          | (Some(_), None) => onChange(Some({Value.modifier: "", value: newValue}))
          }
        }}
      />
    </MaterialUi.FormControl>
  </div>
}

let make = React.memoCustomCompareProps(make, (prevProps, nextProps) =>
  !nextProps["accordionExpanded"] ||
  Belt.Option.eq(prevProps["value"], nextProps["value"], (a, b) =>
    Value.modifier(a) == Value.modifier(b) &&
      Belt.Option.eq(Value.value(a), Value.value(b), (a, b) => a == b)
  )
)
