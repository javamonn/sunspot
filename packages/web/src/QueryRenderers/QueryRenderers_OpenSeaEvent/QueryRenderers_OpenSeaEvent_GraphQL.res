module OrderSection_OpenSeaEvent = OrderSection.Fragment_OrderSection_OpenSeaEvent
module OrderSection_Header_Account = OrderSection_Header.Fragment_OrderSection_Header_Account

module Query_OpenSeaEvent = %graphql(`
  query OpenSeaEvent($contractAddress: String!, $id: AWSTimestamp!, $accountAddress: String!, $getSeaportOrderInput: GetSeaportOrderInput!) {
    openSeaEvent: getOpenSeaEvent(contractAddress: $contractAddress, id: $id) {
      id
      ...OrderSection_OpenSeaEvent
    }
    seaportOrder: getSeaportOrder(input: $getSeaportOrderInput) {
      data 
    }
    account: getAccount(address: $accountAddress) {
      address
      quickbuyFee
      subscription {
        accountAddress
        type_: type  
      }
      ...OrderSection_Header_Account
    }
  }
`)
