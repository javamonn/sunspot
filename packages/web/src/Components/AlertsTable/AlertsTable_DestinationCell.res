@react.component
let make = (~row) =>
  row
  ->AlertsTable_Types.destination
  ->Belt.Option.map(destination =>
    <MaterialUi.ListItem disableGutters={true}>
      {destination
      ->AlertsTable_Types.iconUrl
      ->Belt.Option.map(iconUrl =>
        <MaterialUi.Avatar
          classes={MaterialUi.Avatar.Classes.make(~root=Cn.make(["w-8", "h-8"]), ())}>
          <img src={iconUrl} />
        </MaterialUi.Avatar>
      )
      ->Belt.Option.getWithDefault(React.null)}
      <MaterialUi.ListItemText
        classes={MaterialUi.ListItemText.Classes.make(
          ~root=Cn.make(destination->AlertsTable_Types.iconUrl->Js.Option.isSome ? ["ml-3"] : []),
          ~primary=Cn.make(["text-sm"]),
          ~secondary=Cn.make(["text-sm"]),
          (),
        )}
        primary={destination->AlertsTable_Types.primary->React.string}
        secondary=?{destination->AlertsTable_Types.secondary->Belt.Option.map(React.string)}
      />
    </MaterialUi.ListItem>
  )
  ->Belt.Option.getWithDefault(React.null)
