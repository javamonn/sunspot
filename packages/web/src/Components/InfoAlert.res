@react.component
let make = (
  ~text,
  ~className="",
  ~backgroundColorClassName="bg-gray-100",
  ~borderColorClassName="border-darkDisabled",
  ~style=?,
  ~hideIcon=false,
  ~children=?,
) =>
  <div
    className={Cn.make([
      "flex",
      "flex-col",
      "flex-1",
      "text-darkSecondary",
      "border",
      "border-solid",
      "rounded",
      "text-sm",
      "font-mono",
      className,
      backgroundColorClassName,
      borderColorClassName,
    ])}
    style=?{style}>
    <div className={Cn.make(["flex", "flex-row", "items-center", "p-6"])}>
      {!hideIcon
        ? <Externals.MaterialUi_Icons.Error
            className={Cn.make(["w-5", "h-5", "mr-4", "opacity-50"])}
          />
        : React.null}
      {text}
    </div>
    {switch children {
    | Some(children) => <> <MaterialUi.Divider /> {children} </>
    | None => React.null
    }}
  </div>
