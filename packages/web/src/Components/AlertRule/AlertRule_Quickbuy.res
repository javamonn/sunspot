@react.component
let make = (~value, ~onChange) =>
  <MaterialUi.FormControl
    classes={MaterialUi.FormControl.Classes.make(
      ~root=Cn.make([
        "flex",
        "mt-8",
        "flex-row",
        "border",
        "border-darkDivider",
        "rounded",
        "border-solid",
        "p-4",
      ]),
      (),
    )}>
    <div className={Cn.make(["flex", "items-center", "justify-center"])}>
      <MaterialUi.Checkbox
        color=#Primary
        checked={value}
        onChange={_ => onChange()}
        classes={MaterialUi.Checkbox.Classes.make(~root=Cn.make(["p-0", "mr-4"]), ())}
      />
    </div>
    <div className={Cn.make(["flex", "flex-col"])}>
      <MaterialUi.Typography variant=#Subtitle2>
        {React.string("quick-buy")}
      </MaterialUi.Typography>
      <MaterialUi.FormHelperText>
        {React.string(
          "automatically prompt a transaction to buy the asset when an alert is clicked.",
        )}
      </MaterialUi.FormHelperText>
    </div>
  </MaterialUi.FormControl>
