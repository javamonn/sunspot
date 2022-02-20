type destinationOAuthAccessToken = {
  accessToken: string,
  refreshToken: string,
  scope: string,
  expiresAt: string,
  tokenType: string,
}

module WebPushTemplate = {
  @deriving(accessors)
  type t = {title: string, body: string, isThumbnailImageSize: bool}

  let defaultSaleTemplate = {
    title: "{eventType}: {assetName} - {tokenPrice}",
    body: "{collectionName}\n{alertRulesSatisfied}",
    isThumbnailImageSize: true,
  }

  let defaultListingTemplate = {
    title: "{eventType}: {assetName} - {tokenPrice}",
    body: "{collectionName}\n{alertRulesSatisfied}",
    isThumbnailImageSize: true,
  }
}

module TwitterTemplate = {
  @deriving(accessors)
  type t = {text: string}

  let defaultListingTemplate = {text: "{eventType}: {assetName} - {tokenPrice}\n\n{assetUrl}"}
  let defaultSaleTemplate = {text: "{eventType}: {assetName} - {tokenPrice}\n\n{assetUrl}"}
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
        inline: true,
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
    displayProperties: false,
    isThumbnailImageSize: true,
    fields: Some([
      {
        name: "event",
        value: "{eventType}",
        inline: true,
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

module Value = {
  type t =
    | WebPushAlertDestination({template: option<WebPushTemplate.t>})
    | DiscordAlertDestination({
        guildId: string,
        channelId: string,
        clientId: string,
        template: option<DiscordTemplate.t>,
      })
    | SlackAlertDestination({channelId: string, incomingWebhookUrl: string})
    | TwitterAlertDestination({
        userId: string,
        accessToken: destinationOAuthAccessToken,
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
    accessToken: destinationOAuthAccessToken,
  }

  type t =
    | DiscordAlertDestinationOption(discordDestinationOption)
    | SlackAlertDestinationOption(slackDestinationOption)
    | TwitterAlertDestinationOption(twitterDestinationOption)
}
