let pushNotificationDestinationId = "push-notification"
let destinationIdAddDiscordIntegration = "add-discord-integration"
let destinationIdAddSlackIntegration = "add-slack-integration"

let discordIconUrl = "/discord-icon.svg"
let slackIconUrl = "/slack-icon.svg"

module Value = {
  type t =
    | WebPushAlertDestination
    | DiscordAlertDestination({guildId: string, channelId: string})
    | SlackAlertDestination({channelId: string, incomingWebhookUrl: string})
}

module Option = {
  type t =
    | DiscordAlertDestinationOption({
        guildId: string,
        guildIconUrl: option<string>,
        channelId: string,
        channelName: string,
        guildName: string,
      })
    | SlackAlertDestinationOption({
        teamName: string,
        channelName: string,
        channelId: string,
        incomingWebhookUrl: string,
      })
}

@react.component
let make = (
  ~value,
  ~onChange,
  ~onConnectDiscord,
  ~onConnectSlack,
  ~destinationOptions,
  ~disabled=?,
) => {
  let handleChange = (ev, _) => {
    let target = ev->ReactEvent.Form.target
    target["value"]
    ->Belt.Option.flatMap(newDestination =>
      if newDestination == pushNotificationDestinationId {
        Some(Value.WebPushAlertDestination)
      } else if newDestination == destinationIdAddDiscordIntegration {
        onConnectDiscord()
        None
      } else if newDestination == destinationIdAddSlackIntegration {
        onConnectSlack()
        None
      } else {
        destinationOptions
        ->Belt.Array.getBy(opt =>
          switch opt {
          | Option.DiscordAlertDestinationOption({channelId}) => channelId == newDestination
          | SlackAlertDestinationOption({channelId}) => channelId == newDestination
          }
        )
        ->Belt.Option.map(opt =>
          switch opt {
          | DiscordAlertDestinationOption({guildId, channelId}) =>
            Value.DiscordAlertDestination({
              guildId: guildId,
              channelId: channelId,
            })
          | SlackAlertDestinationOption({incomingWebhookUrl, channelId}) =>
            Value.SlackAlertDestination({
              incomingWebhookUrl: incomingWebhookUrl,
              channelId: channelId,
            })
          }
        )
      }
    )
    ->Belt.Option.forEach(newDestination => {
      onChange(newDestination)
    })
  }

  let unwrappedValue = switch value {
  | Value.WebPushAlertDestination => MaterialUi.Select.Value.string(pushNotificationDestinationId)
  | DiscordAlertDestination({channelId}) => MaterialUi.Select.Value.string(channelId)
  | SlackAlertDestination({channelId}) => MaterialUi.Select.Value.string(channelId)
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
      disabled=?{disabled}
      classes={MaterialUi.Select.Classes.make(~root=Cn.make(["h-10", "leading-10"]), ())}>
      <MaterialUi.MenuItem
        classes={MaterialUi.MenuItem.Classes.make(~root=Cn.make(["py-3"]), ())}
        value={MaterialUi.MenuItem.Value.string(pushNotificationDestinationId)}>
        {React.string("push notification (this device)")}
      </MaterialUi.MenuItem>
      {Belt.Array.length(destinationOptions) > 0 ? <MaterialUi.Divider /> : React.null}
      {destinationOptions
      ->Belt.Array.map(opt => {
        let (id, name, iconUrl) = switch opt {
        | Option.DiscordAlertDestinationOption({
            channelId,
            guildIconUrl,
            channelName,
            guildName,
          }) => (
            channelId,
            `#${channelName} (${guildName})`,
            guildIconUrl->Belt.Option.getWithDefault(discordIconUrl),
          )
        | SlackAlertDestinationOption({teamName, channelName, channelId}) => (
            channelId,
            `${channelName} (${teamName})`,
            slackIconUrl,
          )
        }

        <MaterialUi.MenuItem
          key={id}
          value={id->MaterialUi.MenuItem.Value.string}
          classes={MaterialUi.MenuItem.Classes.make(~root=Cn.make(["whitespace-pre", "h-14"]), ())}>
          <div className={Cn.make(["absolute"])}>
            <MaterialUi.Avatar
              classes={MaterialUi.Avatar.Classes.make(~root=Cn.make(["bg-gray-200"]), ())}>
              <img
                src={iconUrl}
                className={iconUrl == discordIconUrl
                  ? Cn.make(["w-5", "h-5", "opacity-70"])
                  : Cn.make([])}
              />
            </MaterialUi.Avatar>
          </div>
          <span className={Cn.make(["ml-14"])}> {React.string(name)} </span>
        </MaterialUi.MenuItem>
      })
      ->React.array}
      <MaterialUi.Divider />
      <MaterialUi.MenuItem
        value={MaterialUi.MenuItem.Value.string(destinationIdAddDiscordIntegration)}>
        <MaterialUi.Avatar
          classes={MaterialUi.Avatar.Classes.make(
            ~root=Cn.make(["bg-gray-200", "text-darkDisabled"]),
            (),
          )}>
          <Externals.MaterialUi_Icons.Add />
        </MaterialUi.Avatar>
        <span className={Cn.make(["ml-2"])}> {React.string("connect discord")} </span>
      </MaterialUi.MenuItem>
      <MaterialUi.MenuItem
        value={MaterialUi.MenuItem.Value.string(destinationIdAddSlackIntegration)}>
        <MaterialUi.Avatar
          classes={MaterialUi.Avatar.Classes.make(
            ~root=Cn.make(["bg-gray-200", "text-darkDisabled"]),
            (),
          )}>
          <Externals.MaterialUi_Icons.Add />
        </MaterialUi.Avatar>
        <span className={Cn.make(["ml-2"])}> {React.string("connect slack")} </span>
      </MaterialUi.MenuItem>
    </MaterialUi.Select>
  </MaterialUi.FormControl>
}
