exception AlertDestinationRequired
exception AlertCollectionRequired

module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRule
module Mutation_UpdateAlertRule = %graphql(`
  mutation UpdateAlertRuleInput($input: UpdateAlertRuleInput!) {
    alertRule: updateAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

module Mutation_DeleteAlertRule = %graphql(`
  mutation DeleteAlertRule($input: DeleteAlertRuleInput!) {
    alertRule: deleteAlertRule(input: $input) {
      id
    }
  }
`)

let getUpdateAlertRuleDestination = (~value, ~onShowSnackbar) => {
  open Mutation_UpdateAlertRule

  switch AlertModal.Value.destination(value) {
  | Some(AlertRule_Destination.Types.Value.WebPushAlertDestination({template})) =>
    Services.PushNotification.checkPermissionAndGetSubscription(
      ~onShowSnackbar,
    ) |> Js.Promise.then_(pushSubscriptionResult => {
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
              template: template->Belt.Option.map(template => {
                title: template.title,
                body: template.body,
                isThumbnailImageSize: template.isThumbnailImageSize,
                quickbuy: None,
              }),
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
      clientId,
      guildId,
      template,
      roles,
    })) =>
    Js.Promise.resolve(
      Ok({
        discordAlertDestination: Some({
          guildId: guildId,
          clientId: Some(clientId),
          channelId: channelId,
          roles: roles->Belt.Array.map(r => {id: r.id, name: r.name})->Js.Option.some,
          template: template->Belt.Option.map(template => {
            title: template->AlertRule_Destination.Types.DiscordTemplate.title,
            description: template->AlertRule_Destination.Types.DiscordTemplate.description,
            content: template->AlertRule_Destination.Types.DiscordTemplate.content,
            displayProperties: template
            ->AlertRule_Destination.Types.DiscordTemplate.displayProperties
            ->Js.Option.some,
            isThumbnailImageSize: template
            ->AlertRule_Destination.Types.DiscordTemplate.isThumbnailImageSize
            ->Js.Option.some,
            quickbuy: None,
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
        slackAlertDestination: Some({
          channelId: channelId,
          incomingWebhookUrl: incomingWebhookUrl,
        }),
        discordAlertDestination: None,
        webPushAlertDestination: None,
        twitterAlertDestination: None,
      }),
    )
  | Some(AlertRule_Destination.Types.Value.TwitterAlertDestination({
      userId,
      accessToken,
      userAuthenticationToken,
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
          accessToken: accessToken->Belt.Option.map(accessToken => {
            accessToken: accessToken.accessToken,
            refreshToken: accessToken.refreshToken,
            tokenType: accessToken.tokenType,
            scope: accessToken.scope,
            expiresAt: accessToken.expiresAt,
          }),
          userAuthenticationToken: userAuthenticationToken->Belt.Option.map(
            userAuthenticationToken => {
              apiKey: userAuthenticationToken.apiKey,
              apiSecret: userAuthenticationToken.apiSecret,
              userAccessToken: userAuthenticationToken.userAccessToken,
              userAccessSecret: userAuthenticationToken.userAccessSecret,
            },
          ),
        }),
      }),
    )
  | None => Js.Promise.resolve(Belt.Result.Error(AlertDestinationRequired))
  }
}

let getUpdateAlertRuleInput = (~oldValue, ~newValue, ~accountAddress, ~destination) => {
  open Mutation_UpdateAlertRule

  let macroRelativeChangeEventFilter = switch (
    newValue->AlertModal.Value.eventType,
    newValue->AlertModal.Value.saleVolumeChangeRule,
    newValue->AlertModal.Value.floorPriceChangeRule,
  ) {
  | (#SALE_VOLUME_CHANGE, Some(s), _) =>
    Some({
      alertMacroRelativeChangeEventFilter: Some({
        timeWindow: s.timeWindow,
        timeBucket: Some(s.timeBucket),
        relativeValueChange: s.relativeValueChange,
        absoluteValueChange: s.absoluteValueChange->Belt.Option.map(Belt.Float.fromInt),
        emptyRelativeDiffAbsoluteValueChange: s.emptyRelativeDiffAbsoluteValueChange->Belt.Option.map(
          Belt.Float.fromInt,
        ),
        direction: switch s.changeDirection {
        | #CHANGE_ALL => #ALERT_EQUAL
        | #CHANGE_INCREASE => #ALERT_ABOVE
        | #CHANGE_DECREASE => #ALERT_BELOW
        },
      }),
      alertQuantityEventFilter: None,
      alertPriceThresholdEventFilter: None,
      alertAttributesEventFilter: None,
    })
  | (#FLOOR_PRICE_CHANGE, _, Some(s)) =>
    Some({
      alertMacroRelativeChangeEventFilter: Some({
        timeWindow: s.timeWindow,
        relativeValueChange: s.relativeValueChange,
        absoluteValueChange: s.absoluteValueChange
        ->Belt.Option.map(Belt.Float.fromString)
        ->Belt.Option.getWithDefault(None),
        emptyRelativeDiffAbsoluteValueChange: None,
        timeBucket: None,
        direction: switch s.changeDirection {
        | #CHANGE_ALL => #ALERT_EQUAL
        | #CHANGE_INCREASE => #ALERT_ABOVE
        | #CHANGE_DECREASE => #ALERT_BELOW
        },
      }),
      alertQuantityEventFilter: None,
      alertPriceThresholdEventFilter: None,
      alertAttributesEventFilter: None,
    })
  | _ => None
  }

  let quantityEventFilter =
    newValue
    ->AlertModal.Value.quantityRule
    ->Belt.Option.flatMap(rule => {
      let direction = switch AlertRule_Quantity.Value.modifier(rule) {
      | ">" => Some(#ALERT_ABOVE)
      | "<" => Some(#ALERT_BELOW)
      | "=" => Some(#ALERT_EQUAL)
      | _ => None
      }
      let value = rule->AlertRule_Quantity.Value.value->Belt.Option.flatMap(Belt.Int.fromString)

      switch (direction, value) {
      | (Some(direction), Some(value)) =>
        Some({
          alertQuantityEventFilter: Some({
            direction: direction,
            value: value,
          }),
          alertAttributesEventFilter: None,
          alertPriceThresholdEventFilter: None,
          alertMacroRelativeChangeEventFilter: None,
        })
      | _ => None
      }
    })

  let priceEventFilter =
    newValue
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
              imageUrl: Services.PaymentToken.imageUrl(Services.PaymentToken.ethPaymentToken),
            },
          }),
          alertAttributesEventFilter: None,
          alertQuantityEventFilter: None,
          alertMacroRelativeChangeEventFilter: None,
        })
      | _ => None
      }
    })

  let propertiesRule =
    newValue
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
        alertQuantityEventFilter: None,
        alertMacroRelativeChangeEventFilter: None,
      }
    })

  let (disabled, disabledReason, disabledExpiresAt) = switch newValue->AlertModal.Value.disabled {
  | Some(DestinationRateLimitExceeded(disabledExpiresAt)) => (
      Some(true),
      Some(#DESTINATION_RATE_LIMIT_EXCEEDED),
      disabledExpiresAt,
    )
  | Some(DestinationMissingAccess) => (Some(true), Some(#DESTINATION_MISSING_ACCESS), None)
  | Some(Snoozed) => (Some(true), Some(#SNOOZED), None)
  | _ => (None, None, None)
  }

  switch (oldValue->AlertModal.Value.collection, newValue->AlertModal.Value.collection) {
  | (Some(oldCollection), Some(newCollection)) =>
    Js.Promise.resolve(
      Ok({
        alertRule: {
          id: AlertModal.Value.id(newValue),
          accountAddress: accountAddress,
          collectionSlug: AlertModal.CollectionOption.slugGet(newCollection),
          contractAddress: AlertModal.CollectionOption.contractAddressGet(newCollection),
          eventFilters: [
            priceEventFilter,
            propertiesRule,
            quantityEventFilter,
            macroRelativeChangeEventFilter,
          ]->Belt.Array.keepMap(i => i),
          destination: destination,
          eventType: newValue->AlertModal.Value.eventType,
          quickbuy: newValue->AlertModal.Value.quickbuy->Js.Option.some,
          disabled: disabled,
          disabledReason: disabledReason,
          disabledExpiresAt: disabledExpiresAt,
        },
        key: {
          contractAddress: AlertModal.CollectionOption.contractAddressGet(oldCollection),
          id: AlertModal.Value.id(oldValue),
        },
      }),
    )
  | _ => Js.Promise.resolve(Belt.Result.Error(AlertCollectionRequired))
  }
}

let handleUpdateAlertRule = (
  ~input,
  ~mutation: ApolloClient__React_Hooks_UseMutation.MutationTuple.t_mutationFn<
    Mutation_UpdateAlertRule.Mutation_UpdateAlertRule_inner.t,
    Mutation_UpdateAlertRule.Mutation_UpdateAlertRule_inner.t_variables,
    Mutation_UpdateAlertRule.Mutation_UpdateAlertRule_inner.Raw.t_variables,
  >,
) =>
  mutation(
    ~update=({writeFragment}, {data}) => {
      data
      ->Belt.Option.flatMap(({alertRule}) => alertRule)
      ->Belt.Option.forEach(alertRule => {
        let _ = writeFragment(
          ~fragment=module(
            QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRule
          ),
          ~data=alertRule,
          ~id=alertRule.id,
        )
      })
    },
    {
      input: input,
    },
  )

let handleDeleteAlertRule = (
  ~input,
  ~accountAddress,
  ~mutation: ApolloClient__React_Hooks_UseMutation.MutationTuple.t_mutationFn<
    Mutation_DeleteAlertRule.Mutation_DeleteAlertRule_inner.t,
    Mutation_DeleteAlertRule.Mutation_DeleteAlertRule_inner.t_variables,
    Mutation_DeleteAlertRule.Mutation_DeleteAlertRule_inner.Raw.t_variables,
  >,
) =>
  mutation(
    ~update=({writeQuery, readQuery}, {data}) => {
      data
      ->Belt.Option.flatMap(({alertRule}) => alertRule)
      ->Belt.Option.forEach(alertRule => {
        let newItems = switch readQuery(
          ~query=module(
            QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress
          ),
          QueryRenderers_Alerts_GraphQL.makeVariables(~accountAddress),
        ) {
        | Some(Ok({alertRules: Some({items: Some(items)})})) =>
          items
          ->Belt.Array.keep(item =>
            switch item {
            | Some(item) => item.id != alertRule.id
            | None => false
            }
          )
          ->Js.Option.some
        | _ => None
        }

        newItems->Belt.Option.forEach(newItems => {
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
            },
            QueryRenderers_Alerts_GraphQL.makeVariables(~accountAddress),
          )
        })
      })
    },
    {
      input: input,
    },
  )

let defaultValue = AlertModal.Value.empty()

@react.component
let make = (
  ~isOpen,
  ~value=?,
  ~onClose,
  ~onExited,
  ~accountAddress,
  ~destinationOptions,
  ~accountSubscriptionType,
  ~alertCount,
) => {
  let (updateAlertRuleMutation, _) = Mutation_UpdateAlertRule.use()
  let (deleteAlertRuleMutation, _) = Mutation_DeleteAlertRule.use()
  let (newValue, setNewValue) = React.useState(_ => value)
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let _ = React.useEffect1(_ => {
    setNewValue(_ => value)
    None
  }, [value])

  let handleUpdate = () =>
    switch (value, newValue) {
    | (Some(oldValue), Some(newValue)) =>
      getUpdateAlertRuleDestination(~value=newValue, ~onShowSnackbar=openSnackbar)
      |> Js.Promise.then_(destinationResult =>
        switch destinationResult {
        | Ok(destination) =>
          getUpdateAlertRuleInput(~oldValue, ~newValue, ~destination, ~accountAddress)
        | Error(e) => Js.Promise.resolve(Belt.Result.Error(e))
        }
      )
      |> Js.Promise.then_(inputResult =>
        switch inputResult {
        | Ok(input) =>
          handleUpdateAlertRule(
            ~input,
            ~mutation=updateAlertRuleMutation,
          ) |> Js.Promise.then_(_result => {
            onClose()
            openSnackbar(
              ~message=React.string("alert updated."),
              ~type_=Contexts_Snackbar.TypeSuccess,
              ~duration=4000,
              (),
            )
            Js.Promise.resolve()
          })
        | Error(Services.PushNotification.PushNotificationPermissionDenied) =>
          openSnackbar(
            ~message=React.string(
              "browser push notification permission has been denied. enable permission or select an alternate destination.",
            ),
            ~type_=Contexts_Snackbar.TypeError,
            ~duration=8000,
            (),
          )
          Js.Promise.resolve()
        | Error(_) =>
          openSnackbar(
            ~message=<>
              {React.string("an unknown error occurred. try again, and ")}
              <a
                href={Config.discordGuildInviteUrl}
                target="_blank"
                className={Cn.make(["underline"])}>
                {React.string("contact support")}
              </a>
              {React.string("if the issue persists.")}
            </>,
            ~type_=Contexts_Snackbar.TypeError,
            ~duration=8000,
            (),
          )
          Js.Promise.resolve()
        }
      )
    | _ => Js.Promise.resolve()
    }

  let handleDelete = _ =>
    switch (value, value->Belt.Option.flatMap(AlertModal.Value.collection)) {
    | (Some(value), Some(collection)) =>
      let _ =
        handleDeleteAlertRule(
          ~mutation=deleteAlertRuleMutation,
          ~accountAddress,
          ~input={
            contractAddress: collection->AlertModal.CollectionOption.contractAddressGet,
            id: value->AlertModal.Value.id,
          },
        )
        |> Js.Promise.then_(_ => {
          onClose()
          openSnackbar(
            ~message=React.string("alert deleted."),
            ~type_=Contexts_Snackbar.TypeSuccess,
            ~duration=4000,
            (),
          )
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(err => {
          Services.Logger.promiseError(
            "Containers_UpdateAlertModal",
            "Unable to delete AlertRule.",
            err,
          )
          Js.Promise.resolve()
        })
    | _ => ()
    }

  let handleToggleDisabled = () =>
    setNewValue(value =>
      value->Belt.Option.map(value => {
        ...value,
        AlertModal.Value.disabled: switch value->AlertModal.Value.disabled {
        | Some(_) => None
        | None => Some(AlertModal.Value.Snoozed)
        },
      })
    )

  let openSeaAssetsUrl =
    newValue
    ->Belt.Option.getWithDefault(defaultValue)
    ->AlertModal.Utils.makeOpenSeaAssetsUrlForValue
  let contractEtherscanUrl =
    newValue
    ->Belt.Option.getWithDefault(defaultValue)
    ->AlertModal.Value.collection
    ->Belt.Option.map(collection =>
      `https://etherscan.io/address/${collection->AlertModal.CollectionOption.contractAddressGet}`
    )
  let isDisabled =
    newValue
    ->Belt.Option.map(v => v->AlertModal.Value.disabled->Js.Option.isSome)
    ->Belt.Option.getWithDefault(false)

  <AlertModal
    isOpen
    onClose
    onExited={onExited}
    updatingValue=?{value}
    value={newValue->Belt.Option.getWithDefault(defaultValue)}
    onChange={setterFn =>
      setNewValue(value =>
        value->Belt.Option.getWithDefault(defaultValue)->setterFn->Js.Option.some
      )}
    onAction={handleUpdate}
    actionLabel="update"
    title="update alert"
    destinationOptions={destinationOptions}
    accountSubscriptionType
    alertCount
    renderOverflowActionMenuItems={(~onClick) =>
      [
        {
          Js.Option.isSome(openSeaAssetsUrl)
            ? <MaterialUi.MenuItem
                onClick={_ => {
                  onClick()
                  openSeaAssetsUrl->Belt.Option.forEach(Externals.Webapi.Window.open_)
                }}>
                <MaterialUi.ListItemIcon>
                  <img
                    className={Cn.make(["opacity-50"])}
                    src="/opensea-icon.svg"
                    style={ReactDOM.Style.make(~width="1.5rem", ~height="1.5rem", ())}
                  />
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
                    className={Cn.make(["opacity-50"])}
                    style={ReactDOM.Style.make(
                      ~filter="grayscale(100%)",
                      ~width="1.5rem",
                      ~height="1.5rem",
                      (),
                    )}
                    src="/etherscan-icon.svg"
                  />
                </MaterialUi.ListItemIcon>
                <MaterialUi.ListItemText>
                  {React.string("view contract etherscan")}
                </MaterialUi.ListItemText>
              </MaterialUi.MenuItem>
            : React.null
        },
        <MaterialUi.MenuItem
          disabled={switch newValue->Belt.Option.flatMap(AlertModal.Value.disabled) {
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
        <MaterialUi.MenuItem
          onClick={_ => {
            onClick()
            handleDelete()
          }}>
          <MaterialUi.ListItemIcon> <Externals.MaterialUi_Icons.Delete /> </MaterialUi.ListItemIcon>
          <MaterialUi.ListItemText> {React.string("delete")} </MaterialUi.ListItemText>
        </MaterialUi.MenuItem>,
      ]->React.array}
  />
}
