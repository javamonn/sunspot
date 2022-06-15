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
  | Some({
      alertRule: {eventsListItem_EventFilters_AlertRulePartial},
      context: Some(#AlertRuleSatisfiedEvent_SaleContext(context)),
    }) =>
    <EventsListItem_SaleContextItem
      alertRule={eventsListItem_EventFilters_AlertRulePartial}
      context={context}
      onAssetMediaClick={onAssetMediaClick}
      onBuy={onBuy}
      style={style}
      now={now}
    />
  | Some({
      alertRule,
      context: Some(#AlertRuleSatisfiedEvent_MacroRelativeChangeContext(context)),
    }) =>
    <EventsListItem_MacroRelativeChangeContextItem
      alertRule={alertRule}
      context={context}
      style={style}
      now={now}
      onAssetMediaClick={onAssetMediaClick}
    />
  | _ => <EventsListItem_Loading style={style} />
  }
}
