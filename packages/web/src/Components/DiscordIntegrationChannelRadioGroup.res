@deriving(accessors)
type value = {
  id: string,
  name: string,
}

@react.component
let make = (~guildName, ~guildIconUrl=?, ~options, ~value, ~onChange) => {
  let handleChange = ev => {
    let target = ev->ReactEvent.Form.target
    let newId = target["value"]

    options
    ->Belt.Array.getBy(({id}) => id == newId)
    ->Belt.Option.forEach(newValue => onChange(newValue))
  }

  <div className={Cn.make(["border-solid", "border-darkBorder", "border", "rounded-md"])}>
    <MaterialUi.ListItem
      disableGutters={true}
      classes={MaterialUi.ListItem.Classes.make(
        ~root=Cn.make(["border-darkBorder", "border-b", "border-solid", "p-4"]),
        (),
      )}>
      <MaterialUi.Avatar>
        {guildIconUrl
        ->Belt.Option.map(iconUrl => <img src=iconUrl />)
        ->Belt.Option.getWithDefault(React.null)}
      </MaterialUi.Avatar>
      <MaterialUi.ListItemText
        classes={MaterialUi.ListItemText.Classes.make(~root=Cn.make(["ml-4"]), ())}
        primary={React.string(guildName)}
      />
    </MaterialUi.ListItem>
    <MaterialUi.RadioGroup
      value={MaterialUi_Types.Any(value->Belt.Option.map(id))}
      onChange={handleChange}
      classes={MaterialUi.RadioGroup.Classes.make(~root=Cn.make(["p-4"]), ())}>
      {options->Belt.Array.map(({id, name}) =>
        <MaterialUi.FormControlLabel
          key={id}
          value={MaterialUi_Types.Any(id)}
          label={React.string(name)}
          control={<MaterialUi.Radio />}
        />
      )}
    </MaterialUi.RadioGroup>
  </div>
}
