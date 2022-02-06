module DiscordTemplate = AlertRule_Destination_TemplateAccordion_DiscordTemplate
module TwitterTemplate = AlertRule_Destination_TemplateAccordion_TwitterTemplate

@react.component
let make = (~value=?, ~onChange, ~eventType: AlertRule_EventType.t, ~accordionExpanded) =>
  switch value {
  | Some(AlertRule_Destination.Types.Value.DiscordAlertDestination({template} as destination)) =>
    <DiscordTemplate
      value=?{template}
      onChange={newTemplate =>
        onChange(
          AlertRule_Destination.Types.Value.DiscordAlertDestination({
            ...destination,
            template: newTemplate,
          }),
        )}
      eventType={eventType}
    />
  | Some(AlertRule_Destination.Types.Value.TwitterAlertDestination({template} as destination)) =>
    <TwitterTemplate
      value=?{template}
      onChange={newTemplate =>
        onChange(
          AlertRule_Destination.Types.Value.TwitterAlertDestination({
            ...destination,
            template: newTemplate,
          }),
        )}
      eventType={eventType}
    />
  | None => <InfoAlert text={"select a destination to customize alert template."} />
  | _ => <InfoAlert text={"custom templates are not yet supported for this destination."} />
  }

let make = React.memoCustomCompareProps(make, (prevProps, nextProps) =>
  !nextProps["accordionExpanded"] ||
  (nextProps["eventType"] == prevProps["eventType"] &&
    Belt.Option.eq(nextProps["value"], prevProps["value"], (a, b) => a == b))
)
