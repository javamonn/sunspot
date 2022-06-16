%raw(`require('react-image-lightbox/style.css')`)

module OrderSection_AssetDetail_OpenSeaEvent = OrderSection_AssetDetail.Fragment_OrderSection_AssetDetail_OpenSeaEvent
module OrderSection_Header_OpenSeaEvent = OrderSection_Header.Fragment_OrderSection_Header_OpenSeaEvent

module Fragment_OrderSection_OpenSeaEvent = %graphql(`
  fragment OrderSection_OpenSeaEvent on OpenSeaEvent {
    ...OrderSection_AssetDetail_OpenSeaEvent
    ...OrderSection_Header_OpenSeaEvent
  }
`)

@react.component
let make = (
  ~onClickBuy,
  ~executionState,
  ~quickbuy,
  ~openSeaEvent: Fragment_OrderSection_OpenSeaEvent.t,
) => {
  <>
    <OrderSection_Header
      openSeaEvent={openSeaEvent.orderSection_Header_OpenSeaEvent}
      onClickBuy={onClickBuy}
      executionState={executionState}
      quickbuy={quickbuy}
    />
    <OrderSection_AssetDetail openSeaEvent={openSeaEvent.orderSection_AssetDetail_OpenSeaEvent} />
  </>
}
