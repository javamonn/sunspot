@react.component
let make = (
  ~alertRuleSatisfiedEvent: option<
    EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t,
  >,
  ~style,
  ~onAssetMediaClick,
  ~onBuy,
  ~now,
) => {
  switch alertRuleSatisfiedEvent {
  | Some({alertRule, context: #AlertRuleSatisfiedEvent_ListingContext(context)}) =>
    <EventsListItem_ListingContextItem
      alertRule={alertRule}
      context={context}
      onAssetMediaClick={onAssetMediaClick}
      onBuy={onBuy}
      style={style}
      now={now}
    />
  | Some({alertRule, context: #AlertRuleSatisfiedEvent_SaleContext(context)}) =>
    <EventsListItem_SaleContextItem
      alertRule={alertRule}
      context={context}
      onAssetMediaClick={onAssetMediaClick}
      onBuy={onBuy}
      style={style}
      now={now}
    />
  | _ => <EventsListItem_Loading style={style} />
  }
}
