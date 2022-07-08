@react.component
let make = (
  ~alertRuleSatisfiedEvent: option<
    EventsListItem_GraphQL.Fragment_EventsListItem_AlertRuleSatisfiedEvent.t,
  >,
  ~style,
  ~onAssetMediaClick,
  ~onOpenOpenSeaEventDialog,
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
      style={style}
      now={now}
    />
  | Some({
      alertRule: {eventsListItem_EventFilters_AlertRulePartial},
      context: Some(#AlertRuleSatisfiedEvent_OpenSeaEventListingContext(context)),
    }) =>
    <EventsListItem_OpenSeaEventListingContextItem
      alertRule={eventsListItem_EventFilters_AlertRulePartial}
      context={context}
      onAssetMediaClick={onAssetMediaClick}
      onOpenOpenSeaEventDialog={onOpenOpenSeaEventDialog}
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
  | Some({
      createdAt,
      alertRule,
      context: Some(#AlertRuleSatisfiedEvent_ThresholdFloorPriceContext(context)),
    }) =>
    <EventsListItem_ThresholdFloorPriceContextItem
      createdAt={createdAt}
      alertRule={alertRule}
      context={context}
      style={style}
      now={now}
      onAssetMediaClick={onAssetMediaClick}
    />
  | _ => <EventsListItem_Loading style={style} />
  }
}
