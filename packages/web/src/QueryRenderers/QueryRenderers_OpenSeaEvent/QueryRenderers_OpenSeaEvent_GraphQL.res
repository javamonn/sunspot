module OrderSection_OpenSeaEvent = OrderSection.Fragment_OrderSection_OpenSeaEvent

module Query_OpenSeaEvent = %graphql(`
  query OpenSeaEvent($contractAddress: String!, $id: AWSTimestamp!) {
    openSeaEvent: getOpenSeaEvent(contractAddress: $contractAddress, id: $id) {
      id
      ...OrderSection_OpenSeaEvent
    }
  }
`)
