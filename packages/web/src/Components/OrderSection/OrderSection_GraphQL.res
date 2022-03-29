module Fragment_OrderSection_OpenSeaOrder = %graphql(`
  fragment OrderSection_OpenSeaAsset on OpenSeaAsset {
    name
    tokenId
    permalink
    tokenMetadata
    imageUrl
    animationUrl
    collectionSlug
    collection {
      name
      slug
      imageUrl
      contractAddress
    }
    attributes {
      ... on OpenSeaAssetNumberAttribute {
        traitType
        displayType
        numberValue: value
        maxValue
      }
      ... on OpenSeaAssetStringAttribute {
        traitType
        displayType
        stringValue: value
        maxValue
      }
    }
  }

  fragment OrderSection_OpenSeaOrderMetadataAsset on OpenSeaOrderMetadataAsset {
    id  
    address
    quantity
  }

  fragment OrderSection_OpenSeaOrder on OpenSeaOrder {
    id
    basePrice
    paymentTokenContract {
      name
      symbol
      decimals
      address
      imageUrl
      ethPrice
      usdPrice
    }
    listingTime
    expirationTime
    asset {
      ...OrderSection_OpenSeaAsset
    }
    assetBundle {
      name
      permalink
      assets {
        ...OrderSection_OpenSeaAsset
      }
    }
    metadata {
      asset {
        ...OrderSection_OpenSeaOrderMetadataAsset
      }
      bundle {
        assets {
          ...OrderSection_OpenSeaOrderMetadataAsset
        }
        schemas
        name
        description
        externalLink
      }
      schema
    }
  }
`)