let pushNotificationDestinationId = "push-notification"
let discordIconUrl = "/discord-icon.svg"

module Value = {
  type t =
    | WebPushAlertDestination
    | DiscordAlertDestination({guildId: string, channelId: string})
}

module Option = {
  @deriving(accessors)
  type t = {
    guildId: string,
    guildIconUrl: option<string>,
    channelId: string,
    channelName: string,
    guildName: string,
  }
}

@react.component
let make = (~value, ~onChange, ~discordDestinationOptions, ~disabled=?) => {
  let handleChange = (ev, _) => {
    let target = ev->ReactEvent.Form.target
    target["value"]
    ->Belt.Option.flatMap(newDestination =>
      if newDestination == pushNotificationDestinationId {
        Some(Value.WebPushAlertDestination)
      } else {
        discordDestinationOptions
        ->Belt.Array.getBy(opt => Option.channelId(opt) == newDestination)
        ->Belt.Option.map(opt => Value.DiscordAlertDestination({
          guildId: Option.guildId(opt),
          channelId: Option.channelId(opt),
        }))
      }
    )
    ->Belt.Option.forEach(newDestination => {
      onChange(newDestination)
    })
  }

  let unwrappedValue = switch value {
  | Value.WebPushAlertDestination => MaterialUi.Select.Value.string(pushNotificationDestinationId)
  | DiscordAlertDestination({channelId}) => MaterialUi.Select.Value.string(channelId)
  }

  <MaterialUi.FormControl
    classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-8", "w-1/2"]), ())}>
    <MaterialUi.InputLabel shrink=true id="CreateAlertModal_action" htmlFor="">
      {React.string("destination")}
    </MaterialUi.InputLabel>
    <MaterialUi.Select
      labelId="AlertRule_destination"
      value={unwrappedValue}
      fullWidth=true
      onChange={handleChange}
      disabled=?{disabled}>
      <MaterialUi.MenuItem
        classes={MaterialUi.MenuItem.Classes.make(~root=Cn.make(["py-3"]), ())}
        value={MaterialUi.MenuItem.Value.string(pushNotificationDestinationId)}>
        {React.string("push notification (this device)")}
      </MaterialUi.MenuItem>
      {discordDestinationOptions
      ->Belt.Array.map(opt =>
        <MaterialUi.MenuItem
          key={Option.channelId(opt)}
          value={opt->Option.channelId->MaterialUi.MenuItem.Value.string}
          classes={MaterialUi.MenuItem.Classes.make(~root=Cn.make(["whitespace-pre"]), ())}>
          <div className={Cn.make(["inline-block"])}>
            <MaterialUi.Avatar
              classes={MaterialUi.Avatar.Classes.make(~root=Cn.make(["bg-gray-200"]), ())}>
              {opt
              ->Option.guildIconUrl
              ->Belt.Option.map(src => <img src={src} />)
              ->Belt.Option.getWithDefault(
                <img className={Cn.make(["w-5", "h-5", "opacity-70"])} src={discordIconUrl} />,
              )}
            </MaterialUi.Avatar>
          </div>
          <span className={Cn.make(["ml-2"])}>
            {React.string(`#${opt->Option.channelName} (${opt->Option.guildName})`)}
          </span>
        </MaterialUi.MenuItem>
      )
      ->React.array}
    </MaterialUi.Select>
  </MaterialUi.FormControl>
}
