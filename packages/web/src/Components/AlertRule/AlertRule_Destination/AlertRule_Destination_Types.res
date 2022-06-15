type destinationOAuthAccessToken = {
  accessToken: string,
  refreshToken: string,
  scope: string,
  expiresAt: string,
  tokenType: string,
}

type twitterUserAuthenticationToken = {
  apiKey: string,
  apiSecret: string,
  userAccessToken: string,
  userAccessSecret: string,
}

module WebPushTemplate = {
  @deriving(accessors)
  type t = {title: string, body: string, isThumbnailImageSize: bool}

  let defaultSaleTemplate = {
    title: "{eventType}: {assetName} - {tokenPrice}",
    body: "{collectionName} ({collectionFloorTokenPrice} floor)\n{alertRulesSatisfied}",
    isThumbnailImageSize: true,
  }

  let defaultListingTemplate = {
    title: "{eventType}: {assetName} - {tokenPrice}",
    body: "{collectionName} ({collectionFloorTokenPrice} floor)\n{alertRulesSatisfied}",
    isThumbnailImageSize: true,
  }

  let defaultFloorPriceChangeTemplate = {
    title: "floor {changeVerb}: {collectionName}",
    body: "{changeIndicatorArrow} {changeValue} in {timeElapsed}\ncurrent floor: {floorPrice}",
    isThumbnailImageSize: false,
  }

  let defaultSaleVolumeChangeTemplate = {
    title: "sales {changeVerb}: {collectionName}",
    body: "{changeIndicatorArrow} {changeValue} in {timeElapsed}\ncurrent {targetBucket} sales: {targetCount}",
    isThumbnailImageSize: false,
  }
}

module TwitterTemplate = {
  @deriving(accessors)
  type t = {text: string}

  let defaultListingTemplate = {text: "{eventType}: {assetName} - {tokenPrice}\n\n{assetUrl}"}
  let defaultSaleTemplate = {text: "{eventType}: {assetName} - {tokenPrice}\n\n{assetUrl}"}
  let defaultSaleVolumeChangeTemplate = {
    text: "sales {changeVerb}: {collectionName} {changeIndicatorArrow} {changeValue} in {timeElapsed}\ncurrent {targetBucket} sales: {targetCount}\n\n{eventsScatterPlotImageUrl}",
  }
  let defaultFloorPriceChangeTemplate = {
    text: "floor {changeVerb}: {collectionName} {changeIndicatorArrow} {changeValue} in {timeElapsed}\ncurrent floor: {floorPrice}\n\n{eventsScatterPlotImageUrl}",
  }
}

module DiscordTemplate = {
  @deriving(accessors)
  type field = {name: string, value: string, inline: bool}
  @deriving(accessors)
  type t = {
    title: string,
    content: option<string>,
    displayProperties: bool,
    description: option<string>,
    isThumbnailImageSize: bool,
    fields: option<array<field>>,
  }

  let defaultFloorPriceChangeTemplate = {
    content: None,
    title: "floor {changeVerb}: {collectionName} {changeIndicatorArrow} {changeValue} in {timeElapsed}",
    description: None,
    displayProperties: false,
    isThumbnailImageSize: false,
    fields: Some([
      {
        name: "current floor price",
        value: "{floorPrice}",
        inline: false,
      },
      {
        name: "floor price change",
        value: "{changeIndicatorArrow} {changeValue} in {timeElapsed}",
        inline: false,
      },
      {
        name: "15m sales",
        value: "{target15mSaleCount} ({target15mSaleChange})",
        inline: true,
      },
      {
        name: "15m listings",
        value: "{target15mListingCount} ({target15mListingChange})",
        inline: true,
      },
    ]),
  }

  let defaultSaleVolumeChangeTemplate = {
    content: None,
    title: "sales {changeVerb}: {collectionName} {changeIndicatorArrow} {changeValue} in {timeElapsed}",
    description: None,
    displayProperties: false,
    isThumbnailImageSize: false,
    fields: Some([
      {
        name: "{targetBucket} sales",
        value: "{targetCount}",
        inline: false,
      },
      {
        name: "sales change",
        value: "{changeIndicatorArrow} {changeValue} in {timeElapsed}",
        inline: false,
      },
      {
        name: "current floor price",
        value: "{floorPrice}",
        inline: false,
      },
    ]),
  }

  let defaultSaleTemplate = {
    title: "{eventType}: {assetName} - {tokenPrice}",
    content: None,
    description: None,
    displayProperties: false,
    isThumbnailImageSize: true,
    fields: Some([
      {
        name: "event",
        value: "{eventType}",
        inline: false,
      },
      {
        name: "price",
        value: "{tokenPrice} ({usdPrice})",
        inline: true,
      },
      {
        name: "quantity",
        value: "{quantity}",
        inline: true,
      },
      {
        name: "trailing 15 sales floor price",
        value: "{collectionFloorTokenPrice} ({collectionFloorUsdPrice})",
        inline: true,
      },
      {
        name: "transaction",
        value: "[{transactionHash}]({transactionUrl})",
        inline: false,
      },
      {
        name: "seller",
        value: "[{sellerName}]({sellerUrl})",
        inline: true,
      },
      {
        name: "buyer",
        value: "[{buyerName}]({buyerUrl})",
        inline: true,
      },
      {
        name: "alert rules satisfied",
        value: "{alertRulesSatisfied}",
        inline: false,
      },
    ]),
  }

  let defaultListingTemplate = {
    title: "{eventType}: {assetName} - {tokenPrice}",
    content: None,
    description: None,
    displayProperties: true,
    isThumbnailImageSize: true,
    fields: Some([
      {
        name: "event",
        value: "{eventType}",
        inline: false,
      },
      {
        name: "price",
        value: "{tokenPrice} ({usdPrice})",
        inline: true,
      },
      {
        name: "quantity",
        value: "{quantity}",
        inline: true,
      },
      {
        name: "trailing 15 sales floor price",
        value: "{collectionFloorTokenPrice} ({collectionFloorUsdPrice})",
        inline: true,
      },
      {
        name: "seller",
        value: "[{sellerName}]({sellerUrl})",
        inline: false,
      },
      {
        name: "alert rules satisfied",
        value: "{alertRulesSatisfied}",
        inline: false,
      },
    ]),
  }
}

module DiscordAlertDestination = {
  @deriving(accessors)
  type role = {
    name: string,
    id: string,
  }

  @deriving(accessors)
  type t = {
    guildId: string,
    channelId: string,
    clientId: string,
    roles: array<role>,
    template: option<DiscordTemplate.t>,
  }
}

module Value = {
  type t =
    | WebPushAlertDestination({template: option<WebPushTemplate.t>})
    | DiscordAlertDestination(DiscordAlertDestination.t)
    | SlackAlertDestination({channelId: string, incomingWebhookUrl: string})
    | TwitterAlertDestination({
        userId: string,
        accessToken: option<destinationOAuthAccessToken>,
        userAuthenticationToken: option<twitterUserAuthenticationToken>,
        template: option<TwitterTemplate.t>,
      })
}

module Option = {
  type discordDestinationOption = {
    guildId: string,
    clientId: string,
    guildIconUrl: option<string>,
    channelId: string,
    channelName: string,
    guildName: string,
    roles: array<DiscordAlertDestination.role>,
  }

  type slackDestinationOption = {
    teamName: string,
    channelName: string,
    channelId: string,
    incomingWebhookUrl: string,
  }

  type twitterDestinationOption = {
    userId: string,
    username: string,
    profileImageUrl: string,
    accessToken: option<destinationOAuthAccessToken>,
    userAuthenticationToken: option<twitterUserAuthenticationToken>,
  }

  type t =
    | DiscordAlertDestinationOption(discordDestinationOption)
    | SlackAlertDestinationOption(slackDestinationOption)
    | TwitterAlertDestinationOption(twitterDestinationOption)
}
