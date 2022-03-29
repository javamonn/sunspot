module OrderSection_OpenSeaOrder = OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaOrder

module Query_OpenSeaOrder = %graphql(`
  fragment OpenSeaOrderMetadataAsset on OpenSeaOrderMetadataAsset {
    id  
    address
    quantity
  }
  
  fragment OpenSeaOrderUser on OpenSeaOrderUser {
    address
    config
    profileImgUrl
    username
    userId
  }

  fragment OpenSeaOrderMetadataBundle on OpenSeaOrderMetadataBundle {
    assets {
      ...OpenSeaOrderMetadataAsset
    }
    schemas
    name
    description
    externalLink
  }

  query OpenSeaOrder($collectionSlug: String!, $id: AWSTimestamp!) {
    openSeaOrder: getOpenSeaOrder(collectionSlug: $collectionSlug, id: $id) {
      orderHash
      cancelled
      finalized
      markedInvalid
      metadata {
        asset {
          ...OpenSeaOrderMetadataAsset
        }
        bundle {
          ...OpenSeaOrderMetadataBundle
        }
        schema
      }
      quantity
      exchange
      maker {
        ...OpenSeaOrderUser
      }
      taker {
        ...OpenSeaOrderUser
      }
      feeRecipient {
        ...OpenSeaOrderUser
      }
      makerRelayerFee
      takerRelayerFee
      makerProtocolFee
      takerProtocolFee
      makerReferrerFee
      feeMethod
      side
      saleKind
      target
      howToCall
      calldata
      replacementPattern
      staticTarget
      staticExtradata
      paymentToken
      basePrice
      extra
      currentBounty
      currentPrice
      createdTime
      listingTime
      expirationTime
      salt
      v
      r
      s
      paymentTokenContract {
        name
        symbol
        decimals
        address
        imageUrl
        ethPrice
        usdPrice
      }
      id
      ...OrderSection_OpenSeaOrder
    }
  }
`)
