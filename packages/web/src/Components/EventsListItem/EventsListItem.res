@react.component
let make = (
  ~alertRuleSatisfiedEvent: option<
    EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t,
  >,
  ~style,
  ~onAssetMediaClick,
  ~onClick,
  ~now,
) => {
  switch alertRuleSatisfiedEvent {
  | Some(
      {
        alertRule,
        context: #AlertRuleSatisfiedEvent_ListingContext(context),
      } as alertRuleSatisfiedEvent,
    ) =>
    <EventsListItem_ListingContextItem
      alertRule={alertRule}
      context={context}
      onAssetMediaClick={onAssetMediaClick}
      onClick={() => onClick(~quickbuy=false, ~alertRuleSatisfiedEvent)}
      onBuyClick={() => onClick(~quickbuy=true, ~alertRuleSatisfiedEvent)}
      style={style}
      now={now}
    />
  | _ => <li style={style}> {React.string("loading...")} </li>
  }
}
