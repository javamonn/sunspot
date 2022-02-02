module Types = AlertRule_Destination_Types
open AlertRule_Destination_Types

let pushNotificationDestinationId = "push-notification"
let destinationIdAddDiscordIntegration = "add-discord-integration"
let destinationIdAddSlackIntegration = "add-slack-integration"
let destinationIdAddTwitterIntegration = "add-twitter-integration"

let discordIconUrl = "/discord-icon.svg"
let slackIconUrl = "/slack-icon.svg"

@react.component
let make = (
  ~value,
  ~onChange,
  ~onConnectDiscord,
  ~onConnectSlack,
  ~onConnectTwitter,
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
      } else if newDestination == destinationIdAddTwitterIntegration {
        onConnectTwitter()
        None
      } else {
        destinationOptions
        ->Belt.Array.getBy(opt =>
          switch opt {
          | Option.DiscordAlertDestinationOption({channelId}) => channelId == newDestination
          | SlackAlertDestinationOption({channelId}) => channelId == newDestination
          | TwitterAlertDestinationOption({userId}) => userId === newDestination
          }
        )
        ->Belt.Option.map(opt =>
          switch opt {
          | DiscordAlertDestinationOption({guildId, channelId, clientId}) =>
            Value.DiscordAlertDestination({
              guildId: guildId,
              channelId: channelId,
              clientId: clientId,
              template: None
            })
          | SlackAlertDestinationOption({incomingWebhookUrl, channelId}) =>
            Value.SlackAlertDestination({
              incomingWebhookUrl: incomingWebhookUrl,
              channelId: channelId,
            })
          | TwitterAlertDestinationOption({userId, accessToken}) =>
            Value.TwitterAlertDestination({userId: userId, accessToken: accessToken})
          }
        )
      }
    )
    ->Belt.Option.forEach(newDestination => {
      onChange(newDestination)
    })
  }

  let unwrappedValue = switch value {
  | Some(Value.WebPushAlertDestination) =>
    MaterialUi.Select.Value.string(pushNotificationDestinationId)
  | Some(DiscordAlertDestination({channelId})) => MaterialUi.Select.Value.string(channelId)
  | Some(SlackAlertDestination({channelId})) => MaterialUi.Select.Value.string(channelId)
  | Some(TwitterAlertDestination({userId})) => MaterialUi.Select.Value.string(userId)
  | None => MaterialUi.Select.Value.string("")
  }

  <MaterialUi.FormControl
    classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-8", "w-full"]), ())}>
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
        classes={MaterialUi.MenuItem.Classes.make(
          ~root=Cn.make([
            "py-3",
            Config.isBrowser() && !Services.PushNotification.isSupported()
              ? "cursor-not-allowed"
              : "",
          ]),
          (),
        )}
        value={MaterialUi.MenuItem.Value.string(pushNotificationDestinationId)}
        disabled={Config.isBrowser() && !Services.PushNotification.isSupported()}>
        <div className={Cn.make(["flex", "flex-col"])}>
          <span> {React.string("push notification (this device)")} </span>
          {Config.isBrowser() && !Services.PushNotification.isSupported()
            ? <span className={Cn.make(["text-sm"])}>
                {React.string("web push is not supported by your browser.")}
              </span>
            : React.null}
        </div>
      </MaterialUi.MenuItem>
      {Belt.Array.length(destinationOptions) > 0 ? <MaterialUi.Divider /> : React.null}
      {destinationOptions
      ->Belt.Array.map(opt => {
        let (id, name, iconUrl, displayType) = switch opt {
        | Option.DiscordAlertDestinationOption({
            channelId,
            guildIconUrl,
            channelName,
            guildName,
          }) => (
            channelId,
            `#${channelName} (${guildName})`,
            guildIconUrl->Belt.Option.getWithDefault(discordIconUrl),
            "discord",
          )
        | SlackAlertDestinationOption({teamName, channelName, channelId}) => (
            channelId,
            `${channelName} (${teamName})`,
            slackIconUrl,
            "slack",
          )
        | TwitterAlertDestinationOption({userId, username, profileImageUrl}) => (
            userId,
            `@${username}`,
            profileImageUrl,
            "twitter",
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
          <div className={Cn.make(["flex", "flex-row", "justify-between", "flex-1"])}>
            <span className={Cn.make(["ml-14", "font-medium", "block", "flex-1"])}>
              {React.string(name)}
            </span>
            <span className={Cn.make(["ml-14", "text-darkSecondary", "block"])}>
              {React.string(displayType)}
            </span>
          </div>
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
        <span className={Cn.make(["ml-4"])}> {React.string("connect discord")} </span>
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
        <span className={Cn.make(["ml-4"])}> {React.string("connect slack")} </span>
      </MaterialUi.MenuItem>
      <MaterialUi.MenuItem
        value={MaterialUi.MenuItem.Value.string(destinationIdAddTwitterIntegration)}>
        <MaterialUi.Avatar
          classes={MaterialUi.Avatar.Classes.make(
            ~root=Cn.make(["bg-gray-200", "text-darkDisabled"]),
            (),
          )}>
          <Externals.MaterialUi_Icons.Add />
        </MaterialUi.Avatar>
        <span className={Cn.make(["ml-4"])}> {React.string("connect twitter")} </span>
      </MaterialUi.MenuItem>
    </MaterialUi.Select>
  </MaterialUi.FormControl>
}
