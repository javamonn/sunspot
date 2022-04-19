module OrderSection_OpenSeaOrder = OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder

module Query_OpenSeaOrder = %graphql(`
  query OpenSeaOrder($collectionSlug: String!, $id: AWSTimestamp!) {
    openSeaOrder: getOpenSeaOrder(collectionSlug: $collectionSlug, id: $id) {
      id
      telescopeManualAtomicMatchInput {
        feeValue
        wyvernExchangeValue
        signature
        wyvernExchangeData
      }
      ...OrderSection_OpenSeaOrder
    }
  }
`)
