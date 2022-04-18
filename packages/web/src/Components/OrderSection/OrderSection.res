%raw(`require('react-image-lightbox/style.css')`)

@react.component
let make = (
  ~onClickBuy,
  ~executionState,
  ~openSeaOrderFragment: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder.t,
  ~quickbuy,
) => {
  <>
    <OrderSection_Header
      onClickBuy={onClickBuy}
      executionState={executionState}
      openSeaOrderFragment={openSeaOrderFragment}
      quickbuy={quickbuy}
    />
    <OrderSection_AssetDetail openSeaOrderFragment={openSeaOrderFragment} />
  </>
}
