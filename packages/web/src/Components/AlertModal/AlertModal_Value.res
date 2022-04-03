type disabledReason =
  | DestinationRateLimitExceeded(option<Js.Json.t>)
  | DestinationMissingAccess
  | Snoozed

@deriving(accessors)
type t = {
  id: string,
  eventType: AlertRule_EventType.t,
  collection: option<AlertModal_Types.CollectionOption.t>,
  priceRule: option<AlertRule_Price.t>,
  propertiesRule: option<AlertRule_Properties.Value.t>,
  quantityRule: option<AlertRule_Quantity.Value.t>,
  saleVolumeChangeRule: option<AlertModal_AlertRules_SaleVolumeChange.t>,
  floorPriceChangeRule: option<AlertModal_AlertRules_FloorPriceChange.t>,
  destination: option<AlertRule_Destination.Types.Value.t>,
  disabled: option<disabledReason>,
  quickbuy: bool,
}

let make = (
  ~id,
  ~collection,
  ~priceRule,
  ~propertiesRule,
  ~quantityRule,
  ~saleVolumeChangeRule,
  ~floorPriceChangeRule,
  ~destination,
  ~eventType,
  ~disabled,
  ~quickbuy,
) => {
  id: id,
  collection: collection,
  eventType: eventType,
  priceRule: priceRule,
  propertiesRule: propertiesRule,
  quantityRule: quantityRule,
  destination: destination,
  saleVolumeChangeRule: saleVolumeChangeRule,
  floorPriceChangeRule: floorPriceChangeRule,
  disabled: disabled,
  quickbuy: quickbuy,
}

let empty = () => {
  id: Externals.UUID.make(),
  collection: None,
  priceRule: None,
  propertiesRule: None,
  quantityRule: None,
  saleVolumeChangeRule: None,
  floorPriceChangeRule: None,
  eventType: #LISTING,
  destination: Config.isBrowser() && Services.PushNotification.isSupported()
    ? Some(AlertRule_Destination.Types.Value.WebPushAlertDestination({template: None}))
    : None,
  disabled: None,
  quickbuy: false,
}
