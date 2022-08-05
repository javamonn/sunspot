@react.component
let make = (~title, ~subtitle, ~features, ~disabled, ~onClick, ~labelText, ~isActioning) => {
  <div
    className={Cn.make([
      "border",
      "border-solid",
      "border-darkBorder",
      "rounded",
      "flex",
      "flex-col",
      "flex-1",
    ])}>
    <div className={Cn.make(["flex-1", "flex", "flex-col", "pb-10"])}>
      <div className={Cn.make(["border-b", "border-solid", "border-darkBorder", "text-lg", "p-4"])}>
        <h2 className={Cn.make(["underline"])}> {React.string(title)} </h2>
        <h1 className={Cn.make(["font-bold", "mt-4"])}> {React.string(subtitle)} </h1>
      </div>
      <ul className={Cn.make(["list-disc", "list-outside", "pl-10", "pr-4", "pt-4", "space-y-2"])}>
        {features->Belt.Array.map(feature => <li> {React.string(feature)} </li>)->React.array}
      </ul>
    </div>
    <MaterialUi.Button
      disabled={disabled}
      variant=#Contained
      color=#Primary
      size=#Large
      classes={MaterialUi.Button.Classes.make(
        ~label=Cn.make(["lowercase", "font-bold", "py-2"]),
        (),
      )}
      onClick={_ => onClick()}>
      {if isActioning {
        <>
          {React.string(labelText)}
          <MaterialUi.LinearProgress
            color=#Primary
            classes={MaterialUi.LinearProgress.Classes.make(
              ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
              (),
            )}
            variant=#Indeterminate
          />
        </>
      } else {
        React.string(labelText)
      }}
    </MaterialUi.Button>
  </div>
}
