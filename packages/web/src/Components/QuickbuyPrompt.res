@react.component
let make = (~className=?) =>
  <div
    className={Cn.make([
      "flex",
      "flex-row",
      "items-center",
      "border",
      "border-solid",
      "rounded",
      "border-darkBorder",
      "p-4",
      className->Belt.Option.getWithDefault(""),
    ])}>
    <Externals_MaterialUi_Icons.Info
      className={Cn.make(["w-4", "h-4", "text-darkDisabled", "mr-4", "block"])}
    />
    <span className={Cn.make(["text-xs", "text-darkSecondary", "font-mono", "leading-none", "block"])}>
      {React.string("enable ")}
      <b> {React.string("quickbuy")} </b>
      {React.string(" to prompt a buy tx automatically when viewing the events feed or an alert is clicked.")}
    </span>
  </div>
