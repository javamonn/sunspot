%raw(`require('react-image-lightbox/style.css')`)

module OrderSection_AssetDetail_OpenSeaOrder = OrderSection_AssetDetail.Fragment_OrderSection_AssetDetail_OpenSeaOrder
module OrderSection_Header_OpenSeaOrder = OrderSection_Header.Fragment_OrderSection_Header_OpenSeaOrder

module Fragment_OrderSection_OpenSeaOrder = %graphql(`
  fragment OrderSection_OpenSeaOrder on OpenSeaOrder {
    ...OrderSection_AssetDetail_OpenSeaOrder
    ...OrderSection_Header_OpenSeaOrder
  }
`)

@react.component
let make = (
  ~onClickBuy,
  ~executionState,
  ~quickbuy,
  ~openSeaOrder: Fragment_OrderSection_OpenSeaOrder.t,
) => {
  <>
    <OrderSection_Header
      openSeaOrder={openSeaOrder.orderSection_Header_OpenSeaOrder}
      onClickBuy={onClickBuy}
      executionState={executionState}
      quickbuy={quickbuy}
    />
    <OrderSection_AssetDetail openSeaOrder={openSeaOrder.orderSection_AssetDetail_OpenSeaOrder} />
  </>
}
