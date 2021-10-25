module Price = {
  @deriving(accessors)
  type t = {
    id: string,
    modifier: string,
    value: option<string>,
  }
  let makeRule = (~id, ~modifier, ~value) => {
    id: id,
    modifier: modifier,
    value: value,
  }

  @react.component
  let make = (~value, ~onChange, ~onRemove) =>
    <div className={Cn.make(["flex", "flex-row", "mt-8"])}>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root={Cn.make(["flex-1"])}, ())}>
        <MaterialUi.InputLabel shrink=true id={`CreateAlertModal_${id(value)}_rule`} htmlFor="">
          {React.string("rule")}
        </MaterialUi.InputLabel>
        <MaterialUi.Tooltip
          title={React.string(
            "Only price-based rules are currently supported, but more are coming soon.",
          )}>
          <MaterialUi.Select
            labelId={`CreateAlertModal_${id(value)}_rule`}
            value={MaterialUi.Select.Value.string("price")}
            disabled=true
            fullWidth=true>
            <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("price")}>
              {React.string("price")}
            </MaterialUi.MenuItem>
          </MaterialUi.Select>
        </MaterialUi.Tooltip>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex-1", "ml-4"]), ())}>
        <MaterialUi.InputLabel shrink=true id={`CreateAlertModal_${id(value)}_modifier`} htmlFor="">
          {React.string("modifier")}
        </MaterialUi.InputLabel>
        <MaterialUi.Select
          labelId="CreateAlertModal_rule"
          value={value->modifier->MaterialUi.Select.Value.string}
          fullWidth=true
          onChange={(ev, _) => {
            let target = ev->ReactEvent.Form.target
            let newModifier = target["value"]
            onChange({...value, modifier: newModifier})
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
          _type="number"
          _InputLabelProps={{"shrink": true}}
          _InputProps={{"inputMode": "numeric"}}
          value=?{value.value->Belt.Option.map(MaterialUi.TextField.Value.string)}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]
            onChange({...value, value: newValue})
          }}
        />
      </MaterialUi.FormControl>
      <MaterialUi.IconButton
        onClick={_ => onRemove()}
        size=#Small
        style={ReactDOM.Style.make(~width="48px", ~height="48px", ())}
        classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["flex-shrink-0"]), ())}>
        <Externals.MaterialUi_Icons.Close className={Cn.make(["text-darkDisabled"])} />
      </MaterialUi.IconButton>
    </div>
}

module Prompt = {
  @react.component
  let make = (~onCreate, ~className) => {
    let handleClick = () => {
      let rule = Price.makeRule(~id=Externals.UUID.make(), ~modifier="<", ~value=None)
      onCreate(rule)
    }

    <MaterialUi.FormControl classes={MaterialUi.FormControl.Classes.make(~root=className, ())}>
      <MaterialUi.Button
        startIcon={<Externals.MaterialUi_Icons.Add />}
        variant=#Outlined
        color=#Secondary
        onClick={_ => handleClick()}
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["normal-case", "items-center", "justify-start"]),
          (),
        )}>
        {<span className={Cn.make(["items-start", "flex", "flex-col", "ml-4"])}>
          <span className={Cn.make(["text-darkPrimary"])}> {React.string("add rule")} </span>
          <span className={Cn.make(["text-darkSecondary"])}>
            {React.string("optionally filter events on price")}
          </span>
        </span>}
      </MaterialUi.Button>
    </MaterialUi.FormControl>
  }
}
