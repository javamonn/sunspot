exception AlertDestinationRequired
exception AlertCollectionRequired
exception PushNotificationPermissionDenied

module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRule
module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRuleInput($input: CreateAlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

let getCreateAlertRuleDestination = (~value) => {
  open Mutation_CreateAlertRule

  switch AlertModal.Value.destination(value) {
  | Some(AlertRule_Destination.Types.Value.WebPushAlertDestination) =>
    Services.PushNotification.permissionState()
    |> Js.Promise.then_(permissionState =>
      switch permissionState {
      | #denied => Js.Promise.resolve(Error(PushNotificationPermissionDenied))
      | _ =>
        Services.PushNotification.getSubscription()
        |> Js.Promise.then_(subscription => {
          switch subscription {
          | Some(subscription) => Js.Promise.resolve(subscription)
          | None => Services.PushNotification.subscribe()
          }
        })
        |> Js.Promise.then_(subscription => Js.Promise.resolve(Ok(subscription)))
      }
    )
    |> Js.Promise.then_(pushSubscriptionResult => {
      switch pushSubscriptionResult {
      | Ok(pushSubscription) =>
        open Externals.ServiceWorkerGlobalScope.PushSubscription
        let s = getSerialized(pushSubscription)

        Js.Promise.resolve(
          Ok({
            webPushAlertDestination: Some({
              endpoint: s->endpoint,
              keys: {
                p256dh: s->keys->p256dh,
                auth: s->keys->auth,
              },
            }),
            discordAlertDestination: None,
            slackAlertDestination: None,
            twitterAlertDestination: None,
          }),
        )
      | Error(e) => Js.Promise.resolve(Error(e))
      }
    })
  | Some(AlertRule_Destination.Types.Value.DiscordAlertDestination({
      channelId,
      guildId,
      template,
      clientId,
    })) =>
    Js.Promise.resolve(
      Ok({
        discordAlertDestination: Some({
          guildId: guildId,
          clientId: Some(clientId),
          channelId: channelId,
          template: template->Belt.Option.map(template => {
            title: template->AlertRule_Destination.Types.DiscordTemplate.title,
            description: template->AlertRule_Destination.Types.DiscordTemplate.description,
            displayProperties: template
            ->AlertRule_Destination.Types.DiscordTemplate.displayProperties
            ->Js.Option.some,
            fields: template
            ->AlertRule_Destination.Types.DiscordTemplate.fields
            ->Belt.Option.map(fields =>
              fields->Belt.Array.map(field => {
                name: field->AlertRule_Destination_Types.DiscordTemplate.name,
                value: field->AlertRule_Destination_Types.DiscordTemplate.value,
                inline: field->AlertRule_Destination_Types.DiscordTemplate.inline,
              })
            ),
          }),
        }),
        webPushAlertDestination: None,
        slackAlertDestination: None,
        twitterAlertDestination: None,
      }),
    )
  | Some(AlertRule_Destination.Types.Value.SlackAlertDestination({
      channelId,
      incomingWebhookUrl,
    })) =>
    Js.Promise.resolve(
      Ok({
        discordAlertDestination: None,
        webPushAlertDestination: None,
        twitterAlertDestination: None,
        slackAlertDestination: Some({
          channelId: channelId,
          incomingWebhookUrl: incomingWebhookUrl,
        }),
      }),
    )
  | Some(AlertRule_Destination.Types.Value.TwitterAlertDestination({
      userId,
      accessToken,
      template,
    })) =>
    Js.Promise.resolve(
      Ok({
        discordAlertDestination: None,
        webPushAlertDestination: None,
        slackAlertDestination: None,
        twitterAlertDestination: Some({
          userId: userId,
          template: template->Belt.Option.map(template => {
            text: template->AlertRule_Destination.Types.TwitterTemplate.text,
          }),
          accessToken: {
            accessToken: accessToken.accessToken,
            refreshToken: accessToken.refreshToken,
            tokenType: accessToken.tokenType,
            scope: accessToken.scope,
            expiresAt: accessToken.expiresAt,
          },
        }),
      }),
    )
  | None => Js.Promise.resolve(Belt.Result.Error(AlertDestinationRequired))
  }
}

let getCreateAlertRuleInput = (~value, ~accountAddress, ~destination) => {
  open Mutation_CreateAlertRule

  let priceEventFilter =
    value
    ->AlertModal.Value.priceRule
    ->Belt.Option.flatMap(rule => {
      let direction = switch AlertRule_Price.modifier(rule) {
      | ">" => Some(#ALERT_ABOVE)
      | "<" => Some(#ALERT_BELOW)
      | _ => None
      }
      let value =
        rule
        ->AlertRule_Price.value
        ->Belt.Option.map(value =>
          value->Services.PaymentToken.formatPrice(Services.PaymentToken.ethPaymentToken)
        )

      switch (direction, value) {
      | (Some(direction), Some(value)) =>
        Some({
          alertPriceThresholdEventFilter: Some({
            direction: direction,
            value: value,
            paymentToken: {
              id: Services.PaymentToken.id(Services.PaymentToken.ethPaymentToken),
              decimals: Services.PaymentToken.decimals(Services.PaymentToken.ethPaymentToken),
              name: Services.PaymentToken.name(Services.PaymentToken.ethPaymentToken),
              symbol: Services.PaymentToken.symbol(Services.PaymentToken.ethPaymentToken),
            },
          }),
          alertAttributesEventFilter: None,
        })
      | _ => None
      }
    })
  let propertiesRule =
    value
    ->AlertModal.Value.propertiesRule
    ->Belt.Option.map(rule => {
      let attributeInputs = rule->Belt.Array.map(a =>
        switch a->AlertRule_Properties.Value.value {
        | StringValue({value}) => {
            openSeaAssetStringAttribute: Some({
              value: value,
              traitType: a->AlertRule_Properties.Value.traitType,
            }),
            openSeaAssetNumberAttribute: None,
          }
        | NumberValue({value}) => {
            openSeaAssetNumberAttribute: Some({
              value: value,
              traitType: a->AlertRule_Properties.Value.traitType,
            }),
            openSeaAssetStringAttribute: None,
          }
        }
      )

      {
        alertAttributesEventFilter: Some({
          attributes: attributeInputs,
        }),
        alertPriceThresholdEventFilter: None,
      }
    })

  let (disabled, disabledReason, disabledExpiresAt) = switch value->AlertModal.Value.disabled {
  | Some(DestinationRateLimitExceeded(disabledExpiresAt)) => (
      Some(true),
      Some(#DESTINATION_RATE_LIMIT_EXCEEDED),
      disabledExpiresAt,
    )
  | Some(DestinationMissingAccess) => (Some(true), Some(#DESTINATION_MISSING_ACCESS), None)
  | Some(Snoozed) => (Some(true), Some(#SNOOZED), None)
  | _ => (None, None, None)
  }

  switch AlertModal.Value.collection(value) {
  | Some(collection) =>
    Js.Promise.resolve(
      Ok({
        id: AlertModal.Value.id(value),
        accountAddress: accountAddress,
        collectionSlug: AlertModal.CollectionOption.slugGet(collection),
        contractAddress: AlertModal.CollectionOption.contractAddressGet(collection),
        eventFilters: [priceEventFilter, propertiesRule]->Belt.Array.keepMap(i => i),
        destination: destination,
        eventType: switch value->AlertModal.Value.eventType {
        | #listing => #LISTING
        | #sale => #SALE
        },
        disabled: disabled,
        disabledReason: disabledReason,
        disabledExpiresAt: disabledExpiresAt,
      }),
    )
  | None => Js.Promise.resolve(Belt.Result.Error(AlertCollectionRequired))
  }
}

let handleCreateAlertRule = (
  ~accountAddress,
  ~input,
  ~mutation: ApolloClient__React_Hooks_UseMutation.MutationTuple.t_mutationFn<
    Mutation_CreateAlertRule.Mutation_CreateAlertRule_inner.t,
    Mutation_CreateAlertRule.Mutation_CreateAlertRule_inner.t_variables,
    Mutation_CreateAlertRule.Mutation_CreateAlertRule_inner.Raw.t_variables,
  >,
) => {
  mutation(
    ~update=({writeQuery, readQuery}, {data}) => {
      data
      ->Belt.Option.flatMap(({alertRule}) => alertRule)
      ->Belt.Option.forEach(alertRule => {
        let (
          newItems,
          discordIntegrations,
          slackIntegrations,
          twitterIntegrations,
        ) = switch readQuery(
          ~query=module(
            QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress
          ),
          QueryRenderers_Alerts_GraphQL.makeVariables(~accountAddress),
        ) {
        | Some(Ok({
            alertRules: Some({items: Some(items)}),
            discordIntegrations,
            slackIntegrations,
            twitterIntegrations,
          })) => (
            Belt.Array.concat([Some(alertRule)], items),
            discordIntegrations,
            slackIntegrations,
            twitterIntegrations,
          )
        | _ => ([Some(alertRule)], None, None, None)
        }

        let _ = writeQuery(
          ~query=module(
            QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress
          ),
          ~data={
            alertRules: Some({
              __typename: "ModelAlertRuleConnection",
              nextToken: None,
              items: Some(newItems),
            }),
            discordIntegrations: discordIntegrations,
            slackIntegrations: slackIntegrations,
            twitterIntegrations: twitterIntegrations,
          },
          QueryRenderers_Alerts_GraphQL.makeVariables(~accountAddress),
        )
      })
    },
    {
      input: input,
    },
  )
}

@react.component
let make = (~isOpen, ~onClose, ~destinationOptions) => {
  let (createAlertRuleMutation, _) = Mutation_CreateAlertRule.use()
  let (value, setValue) = React.useState(() => AlertModal.Value.empty())
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let {openSnackbar}: Contexts.Snackbar.t = React.useContext(Contexts.Snackbar.context)

  let handleExited = () => {
    setValue(_ => AlertModal.Value.empty())
  }

  let handleCreate = (~accountAddress) =>
    getCreateAlertRuleDestination(~value)
    |> Js.Promise.then_(alertRuleDestinationResult =>
      switch alertRuleDestinationResult {
      | Ok(destination) => getCreateAlertRuleInput(~value, ~accountAddress, ~destination)
      | Error(error) => Js.Promise.resolve(Error(error))
      }
    )
    |> Js.Promise.then_(createAlertRuleInputResult =>
      switch createAlertRuleInputResult {
      | Ok(input) =>
        handleCreateAlertRule(
          ~accountAddress,
          ~input,
          ~mutation=createAlertRuleMutation,
        ) |> Js.Promise.then_(_result => {
          onClose()
          openSnackbar(
            ~message="alert created.",
            ~type_=Contexts.Snackbar.TypeSuccess,
            ~duration=4000,
          )
          Js.Promise.resolve()
        })
      | Error(PushNotificationPermissionDenied) =>
        openSnackbar(
          ~message="browser push notification permission has been denied. enable permission or select an alternate destination.",
          ~type_=Contexts.Snackbar.TypeError,
          ~duration=8000,
        )
        Js.Promise.resolve()
      | Error(_) =>
        openSnackbar(
          ~message="an unknown error occurred. try creating the alert again and contact support if the issue persists.",
          ~type_=Contexts.Snackbar.TypeError,
          ~duration=8000,
        )
        Js.Promise.resolve()
      }
    )

  let handleSignIn = () => {
    signIn()
    |> Js.Promise.then_(authentication => {
      let _ = switch authentication {
      | Contexts.Auth.Authenticated({jwt: {accountAddress}}) =>
        let _ = handleCreate(~accountAddress)
      | _ => ()
      }
      Js.Promise.resolve()
    })
    |> Js.Promise.catch(err => {
      Services.Logger.promiseError("Containers_CreateAlertModal", "handleSignIn err", err)
      Js.Promise.resolve()
    })
  }

  let handleAction = () =>
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => handleCreate(~accountAddress)
    | _ => handleSignIn()
    }
  let handleToggleDisabled = () =>
    setValue(value => {
      ...value,
      AlertModal.Value.disabled: switch value->AlertModal.Value.disabled {
      | Some(_) => None
      | None => Some(AlertModal.Value.Snoozed)
      },
    })

  let openSeaAssetsUrl = value->AlertModal.Utils.makeOpenSeaAssetsUrlForValue
  let contractEtherscanUrl =
    value.collection->Belt.Option.map(collection =>
      `https://etherscan.io/address/${collection->AlertModal.CollectionOption.contractAddressGet}`
    )
  let isDisabled = value->AlertModal.Value.disabled->Js.Option.isSome

  let handleRenderOverflowActionMenuItems = if (
    Js.Option.isNone(openSeaAssetsUrl) && Js.Option.isNone(contractEtherscanUrl)
  ) {
    None
  } else {
    Some(
      (~onClick) => [
        {
          Js.Option.isSome(openSeaAssetsUrl)
            ? <MaterialUi.MenuItem
                onClick={_ => {
                  onClick()
                  openSeaAssetsUrl->Belt.Option.forEach(Externals.Webapi.Window.open_)
                }}>
                <MaterialUi.ListItemIcon>
                  <img className={Cn.make(["w-6", "h-6", "opacity-50"])} src="/opensea-icon.svg" />
                </MaterialUi.ListItemIcon>
                <MaterialUi.ListItemText> {React.string("view opensea")} </MaterialUi.ListItemText>
              </MaterialUi.MenuItem>
            : React.null
        },
        {
          Js.Option.isSome(contractEtherscanUrl)
            ? <MaterialUi.MenuItem
                onClick={_ => {
                  onClick()
                  contractEtherscanUrl->Belt.Option.forEach(Externals.Webapi.Window.open_)
                }}>
                <MaterialUi.ListItemIcon>
                  <img
                    className={Cn.make(["w-6", "h-6", "opacity-50"])} src="/etherscan-icon.svg"
                  />
                </MaterialUi.ListItemIcon>
                <MaterialUi.ListItemText>
                  {React.string("view contract etherscan")}
                </MaterialUi.ListItemText>
              </MaterialUi.MenuItem>
            : React.null
        },
        <MaterialUi.MenuItem
          disabled={switch value->AlertModal.Value.disabled {
          | Some(AlertModal.Value.DestinationRateLimitExceeded(_)) => true
          | _ => false
          }}
          onClick={_ => {
            handleToggleDisabled()
          }}>
          <MaterialUi.ListItemIcon>
            <MaterialUi.Checkbox
              color=#Primary
              classes={MaterialUi.Checkbox.Classes.make(
                ~root=Cn.make(["p-0"]),
                ~checked=Cn.make(["opacity-50"]),
                (),
              )}
              checked={!isDisabled}
            />
          </MaterialUi.ListItemIcon>
          <MaterialUi.ListItemText> {React.string("enabled")} </MaterialUi.ListItemText>
        </MaterialUi.MenuItem>,
      ],
    )
  }

  <AlertModal
    isOpen
    onClose
    onExited={handleExited}
    value={value}
    destinationOptions={destinationOptions}
    onChange={setterFn => setValue(value => value->setterFn)}
    onAction={handleAction}
    actionLabel="create"
    title="create alert"
    renderOverflowActionMenuItems=?{handleRenderOverflowActionMenuItems}
  />
}
