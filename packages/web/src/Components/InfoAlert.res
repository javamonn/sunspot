@react.component
let make = (~text, ~className="", ~children=?) =>
  <div
    className={Cn.make([
      "flex",
      "flex-col",
      "flex-1",
      "text-darkSecondary",
      "border",
      "border-solid",
      "border-darkDisabled",
      "rounded",
      "text-sm",
      "bg-gray-100",
      "font-mono",
      className,
    ])}>
    <div className={Cn.make(["flex", "flex-row", "items-center", "p-6"])}>
      <Externals.MaterialUi_Icons.Error className={Cn.make(["w-5", "h-5", "mr-4", "opacity-50"])} />
      {React.string(text)}
    </div>
    {switch children {
    | Some(children) => <> <MaterialUi.Divider /> {children} </>
    | None => React.null
    }}
  </div>
