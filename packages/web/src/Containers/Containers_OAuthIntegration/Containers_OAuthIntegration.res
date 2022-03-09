open Containers_OAuthIntegration_GraphQL

exception SignInFailed
exception InvalidState
exception AlertDestinationRequired
exception InvalidAccessToken

type accessToken = {
  accessToken: string,
  refreshToken: string,
  tokenType: string,
  scope: string,
  expiresAt: string,
}

type integrationParams =
  | Discord({code: string, guildId: string, permissions: int, redirectUri: string})
  | Slack({code: string, redirectUri: string})
  | Twitter({code: string, redirectUri: string})

let integrationDisplayName = integrationParams =>
  switch integrationParams {
  | Discord(_) => "discord server"
  | Slack(_) => "slack workspace"
  | Twitter(_) => "twitter account"
  }

let makeSteps = (
  ~validationError,
  ~setAlertRuleValue,
  ~alertRuleValue,
  ~step0BodyText,
  ~createIntegrationError,
  ~authentication,
  ~params,
  ~createSlackOAuthIntegrationMutationResultData: option<
    Mutation_CreateSlackOAuthIntegration.Mutation_CreateSlackOAuthIntegration_inner.t,
  >,
  ~createDiscordOAuthIntegrationMutationResultData: option<
    Mutation_CreateDiscordOAuthIntegration.Mutation_CreateDiscordOAuthIntegration_inner.t,
  >,
  ~createTwitterOAuthIntegrationMutationResultData: option<
    Mutation_CreateTwitterOAuthIntegration.Mutation_CreateTwitterOAuthIntegration_inner.t,
  >,
) => {
  let connectWalletElement =
    <>
      {createIntegrationError
      ->Belt.Option.map(error =>
        <MaterialUi_Lab.Alert
          severity=#Error classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
          {React.string(error)}
        </MaterialUi_Lab.Alert>
      )
      ->Belt.Option.getWithDefault(React.null)}
      <MaterialUi.Typography
        color=#Primary
        variant=#Body1
        classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-16"]), ())}>
        {React.string(step0BodyText)}
      </MaterialUi.Typography>
    </>

  switch params {
  | Slack(_) => [
      {
        OAuthIntegrationDialog.label: "connect wallet",
        actionLabel: switch authentication {
        | Contexts.Auth.Authenticated(_) => "connect account"
        | _ => "connect wallet"
        },
        element: connectWalletElement,
      },
      {
        label: "configure alert",
        actionLabel: "create alert",
        element: <AlertModal_DialogContent
          isExited={false}
          validationError={validationError}
          value={alertRuleValue}
          onChange={setterFn => setAlertRuleValue(value => value->setterFn)}
          destinationOptions={createSlackOAuthIntegrationMutationResultData
          ->Belt.Option.map(data => [
            AlertRule_Destination.Types.Option.SlackAlertDestinationOption({
              teamName: data.slackIntegration.teamName,
              channelName: data.slackIntegration.channelName,
              channelId: data.slackIntegration.channelId,
              incomingWebhookUrl: data.slackIntegration.incomingWebhookUrl,
            }),
          ])
          ->Belt.Option.getWithDefault([])}
          destinationDisabled={true}
        />,
      },
    ]
  | Twitter(_) => [
      {
        OAuthIntegrationDialog.label: "connect wallet",
        actionLabel: switch authentication {
        | Contexts.Auth.Authenticated(_) => "connect account"
        | _ => "connect wallet"
        },
        element: connectWalletElement,
      },
      {
        label: "configure alert",
        actionLabel: "create alert",
        element: <AlertModal_DialogContent
          isExited={false}
          validationError={validationError}
          value={alertRuleValue}
          onChange={setterFn => setAlertRuleValue(setterFn)}
          destinationOptions={createTwitterOAuthIntegrationMutationResultData
          ->Belt.Option.flatMap(data =>
            data.twitterIntegration.user->Belt.Option.map(user => [
              AlertRule_Destination.Types.Option.TwitterAlertDestinationOption({
                userId: user.id,
                username: user.username,
                profileImageUrl: user.profileImageUrl,
                accessToken: {
                  accessToken: data.twitterIntegration.accessToken.accessToken,
                  refreshToken: data.twitterIntegration.accessToken.refreshToken,
                  scope: data.twitterIntegration.accessToken.scope,
                  expiresAt: data.twitterIntegration.accessToken.expiresAt,
                  tokenType: data.twitterIntegration.accessToken.tokenType,
                },
              }),
            ])
          )
          ->Belt.Option.getWithDefault([])}
          destinationDisabled={true}
        />,
      },
    ]
  | Discord(_) => [
      {
        OAuthIntegrationDialog.label: "connect wallet",
        actionLabel: switch authentication {
        | Authenticated(_) => "connect account"
        | _ => "connect wallet"
        },
        element: connectWalletElement,
      },
      {
        label: "select destination",
        actionLabel: "next",
        element: createDiscordOAuthIntegrationMutationResultData
        ->Belt.Option.map(data => {
          let value = switch alertRuleValue.destination {
          | Some(AlertRule_Destination.Types.Value.DiscordAlertDestination({channelId})) =>
            data.discordIntegration.channels
            ->Belt.Array.getBy(c => c.id == channelId)
            ->Belt.Option.map(c => {
              DiscordIntegrationChannelRadioGroup.id: c.id,
              name: c.name,
            })
          | _ => None
          }
          let handleChange = newValue =>
            setAlertRuleValue(alertRule => {
              ...alertRule,
              destination: Some(
                AlertRule_Destination.Types.Value.DiscordAlertDestination({
                  clientId: data.discordIntegration.clientId->Belt.Option.getWithDefault(
                    Config.discord1ClientId,
                  ),
                  guildId: data.discordIntegration.guildId,
                  roles: data.discordIntegration.roles->Belt.Array.map(r => {
                    AlertRule_Destination.Types.DiscordAlertDestination.id: r.id,
                    name: r.name,
                  }),
                  channelId: newValue->DiscordIntegrationChannelRadioGroup.id,
                  template: None,
                }),
              ),
            })

          <>
            <MaterialUi.Typography
              color=#Primary
              variant=#Body1
              classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-10"]), ())}>
              {React.string("select the channel within ")}
              <span className={Cn.make(["font-bold"])}>
                {React.string(data.discordIntegration.name)}
              </span>
              {React.string(" that will receive alerts:")}
            </MaterialUi.Typography>
            <DiscordIntegrationChannelRadioGroup
              guildName={data.discordIntegration.name}
              guildIconUrl=?{data.discordIntegration.iconUrl}
              options={data.discordIntegration.channels->Belt.Array.map(c => {
                DiscordIntegrationChannelRadioGroup.id: c.id,
                name: c.name,
              })}
              value={value}
              onChange={handleChange}
            />
          </>
        })
        ->Belt.Option.getWithDefault(React.null),
      },
      {
        label: "configure alert",
        actionLabel: "create alert",
        element: <AlertModal_DialogContent
          isExited={false}
          validationError={validationError}
          value={alertRuleValue}
          onChange={setterFn => setAlertRuleValue(setterFn)}
          destinationOptions={createDiscordOAuthIntegrationMutationResultData
          ->Belt.Option.map(data =>
            data.discordIntegration.channels->Belt.Array.map(
              channel => AlertRule_Destination.Types.Option.DiscordAlertDestinationOption({
                channelId: channel.id,
                channelName: channel.name,
                clientId: data.discordIntegration.clientId->Belt.Option.getWithDefault(
                  Config.discord1ClientId,
                ),
                roles: data.discordIntegration.roles->Belt.Array.map(r => {
                  AlertRule_Destination.Types.DiscordAlertDestination.id: r.id,
                  name: r.name,
                }),
                guildId: data.discordIntegration.guildId,
                guildName: data.discordIntegration.name,
                guildIconUrl: data.discordIntegration.iconUrl,
              }),
            )
          )
          ->Belt.Option.getWithDefault([])}
          destinationDisabled={true}
        />,
      },
    ]
  }
}

@react.component
let make = (~onCreated, ~params) => {
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let (validationError, setValidationError) = React.useState(_ => None)
  let (isDialogOpen, setIsDialogOpen) = React.useState(_ => true)
  let (activeStepIdx, setActiveStepIdx) = React.useState(() => 0)
  let (createIntegrationError, setCreateIntegrationError) = React.useState(_ => None)
  let accessToken = React.useRef(None)
  let (isActioning, setIsActioning) = React.useState(() => false)
  let (step0BodyText, _) = React.useState(() =>
    switch authentication {
    | Authenticated(_) =>
      `sunspot is now installed within your ${integrationDisplayName(
          params,
        )}. to start receiving alerts, click next to connect your account.`
    | _ =>
      `sunspot is now installed within your ${integrationDisplayName(
          params,
        )}. to start receiving alerts, connect your wallet to create an account.`
    }
  )
  let (alertRuleValue, setAlertRuleValue) = React.useState(_ => AlertModal.Value.empty())

  let (createAlertRuleMutation, _) = Mutation_CreateAlertRule.use()
  let (createAccessToken, _) = Mutation_CreateAccessToken.use()
  let (
    createDiscordOAuthIntegrationMutation,
    createDiscordOAuthIntegrationMutationResult,
  ) = Mutation_CreateDiscordOAuthIntegration.use()
  let (
    createSlackOAuthIntegrationMutation,
    createSlackOAuthIntegrationMutationResult,
  ) = Mutation_CreateSlackOAuthIntegration.use()
  let (
    createTwitterOAuthIntegrationMutation,
    createTwitterOAuthIntegrationMutationResult,
  ) = Mutation_CreateTwitterOAuthIntegration.use()

  let steps = makeSteps(
    ~createSlackOAuthIntegrationMutationResultData=createSlackOAuthIntegrationMutationResult.data,
    ~createDiscordOAuthIntegrationMutationResultData=createDiscordOAuthIntegrationMutationResult.data,
    ~createTwitterOAuthIntegrationMutationResultData=createTwitterOAuthIntegrationMutationResult.data,
    ~validationError,
    ~setAlertRuleValue,
    ~alertRuleValue,
    ~step0BodyText,
    ~createIntegrationError,
    ~authentication,
    ~params,
  )

  let _ = React.useEffect1(() => {
    let createAccessTokenInput = switch (params, accessToken.current) {
    | (Discord({code, redirectUri}), None) if Js.String2.length(code) > 0 =>
      Some({
        Mutation_CreateAccessToken.oAuthIntegrationType: Config.activeDiscordClient,
        code: code,
        redirectUri: redirectUri,
      })
    | (Twitter({code, redirectUri}), None) if Js.String2.length(code) > 0 =>
      Some({oAuthIntegrationType: #TWITTER, code: code, redirectUri: redirectUri})
    | _ => None
    }

    createAccessTokenInput->Belt.Option.forEach(createAccessTokenInput => {
      let accessTokenP = createAccessToken({
        input: createAccessTokenInput,
      }) |> Js.Promise.then_(result =>
        switch result {
        | Ok(
            result: ApolloClient__React_Types.FetchResult.t__ok<
              Mutation_CreateAccessToken.Mutation_CreateAccessToken_inner.t,
            >,
          ) =>
          let data = result.data.accessToken
          Js.Promise.resolve({
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            expiresAt: data.expiresAt,
            scope: data.scope,
            tokenType: data.tokenType,
          })
        | Error(_) => Js.Promise.reject(InvalidAccessToken)
        }
      )
      accessToken.current = Some(accessTokenP)
    })

    None
  }, [params])

  let handleCreateOAuthIntegration = () => {
    let executeMutation = () => {
      let mutation = switch (params, accessToken.current) {
      | (Discord({guildId, permissions}), Some(accessTokenP)) =>
        accessTokenP
        |> Js.Promise.then_(accessToken =>
          createDiscordOAuthIntegrationMutation({
            input: {
              clientId: Config.activeDiscordClientId,
              guildId: guildId,
              permissions: permissions,
              accessToken: Some({
                accessToken: accessToken.accessToken,
                refreshToken: accessToken.refreshToken,
                scope: accessToken.scope,
                tokenType: accessToken.tokenType,
                expiresAt: accessToken.expiresAt,
              }),
            },
          })
        )
        |> Js.Promise.then_(result =>
          /* * discord alert destination is set in step 2 * */
          result->Belt.Result.map(_ => None)->Js.Promise.resolve
        )
      | (Slack({code, redirectUri}), _) =>
        createSlackOAuthIntegrationMutation({
          input: {
            code: code,
            redirectUri: redirectUri,
          },
        }) |> Js.Promise.then_(result =>
          result
          ->Belt.Result.map((
            result: ApolloClient__React_Types.FetchResult.t__ok<
              Mutation_CreateSlackOAuthIntegration.Mutation_CreateSlackOAuthIntegration_inner.t,
            >,
          ) => Some(
            AlertRule_Destination.Types.Value.SlackAlertDestination({
              channelId: result.data.slackIntegration.channelId,
              incomingWebhookUrl: result.data.slackIntegration.incomingWebhookUrl,
            }),
          ))
          ->Js.Promise.resolve
        )
      | (Twitter(_), Some(accessTokenP)) =>
        accessTokenP
        |> Js.Promise.then_(accessToken =>
          createTwitterOAuthIntegrationMutation({
            input: {
              accessToken: Some({
                accessToken: accessToken.accessToken,
                refreshToken: accessToken.refreshToken,
                scope: accessToken.scope,
                tokenType: accessToken.tokenType,
                expiresAt: accessToken.expiresAt,
              }),
            },
          })
        )
        |> Js.Promise.then_(result => {
          result
          ->Belt.Result.map((
            result: ApolloClient__React_Types.FetchResult.t__ok<
              Mutation_CreateTwitterOAuthIntegration.Mutation_CreateTwitterOAuthIntegration_inner.t,
            >,
          ) =>
            switch result {
            | {data: {twitterIntegration: {user: Some(user), accessToken}}} =>
              Some(
                AlertRule_Destination.Types.Value.TwitterAlertDestination({
                  userId: user.id,
                  template: None,
                  accessToken: {
                    accessToken: accessToken.accessToken,
                    refreshToken: accessToken.refreshToken,
                    expiresAt: accessToken.expiresAt,
                    scope: accessToken.scope,
                    tokenType: accessToken.tokenType,
                  },
                }),
              )
            | _ => None
            }
          )
          ->Js.Promise.resolve
        })
      | (Discord(_), None) => Js.Promise.reject(InvalidAccessToken)
      | (Twitter(_), None) => Js.Promise.reject(InvalidAccessToken)
      }

      mutation
      |> Js.Promise.then_(result => {
        let mappedResult = switch result {
        | Ok(destination) => Ok(destination)
        | Error(e) =>
          Services.Logger.apolloError(
            "Containers_OAuthIntegration",
            "handleCreateOAuthIntegration",
            e,
          )
          Error(
            `an error occurred while connecting your account to your ${integrationDisplayName(
                params,
              )}. try again and contact us for support.`,
          )
        }
        Js.Promise.resolve(mappedResult)
      })
      |> Js.Promise.catch(err => {
        Services.Logger.promiseError(
          "Containers_OAuthIntegration",
          "handleCreateOAuthIntegration",
          err,
        )
        Js.Promise.resolve(
          Error(
            `an error occurred while connecting your account to your ${integrationDisplayName(
                params,
              )}. try again and contact us for support.`,
          ),
        )
      })
    }
    switch authentication {
    | Authenticated(_) => executeMutation()
    | _ =>
      signIn()
      |> Js.Promise.then_(authentication => {
        switch authentication {
        | Contexts.Auth.Authenticated(_) => executeMutation()
        | _ => Js.Promise.reject(SignInFailed)
        }
      })
      |> Js.Promise.catch(err => {
        Services.Logger.promiseError(
          "Containers_OAuthIntegration",
          "handleCreateOAuthIntegration",
          err,
        )
        Js.Promise.resolve(
          Error(
            "an error occurred while connecting your wallet. try again and contact us for support.",
          ),
        )
      })
    }
  }

  let handleCreateAlertRule = () => {
    open Mutation_CreateAlertRule
    setIsActioning(_ => true)

    let macroRelativeChangeEventFilter = switch (
      alertRuleValue->AlertModal.Value.eventType,
      alertRuleValue->AlertModal.Value.saleVolumeChangeRule,
      alertRuleValue->AlertModal.Value.floorPriceChangeRule,
    ) {
    | (#SALE_VOLUME_CHANGE, Some(s), _) =>
      Some({
        alertMacroRelativeChangeEventFilter: Some({
          timeWindow: s.timeWindow,
          timeBucket: Some(s.timeBucket),
          relativeValueChange: s.relativeValueChange,
          absoluteValueChange: s.absoluteValueChange,
          emptyRelativeDiffAbsoluteValueChange: s.emptyRelativeDiffAbsoluteValueChange,
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
          absoluteValueChange: s.absoluteValueChange,
          emptyRelativeDiffAbsoluteValueChange: None,
          timeBucket: None,
        }),
        alertQuantityEventFilter: None,
        alertPriceThresholdEventFilter: None,
        alertAttributesEventFilter: None,
      })
    | _ => None
    }
    let quantityEventFilter =
      alertRuleValue
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
      alertRuleValue
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
            alertQuantityEventFilter: None,
            alertMacroRelativeChangeEventFilter: None,
          })
        | _ => None
        }
      })
    let propertiesEventFilter =
      alertRuleValue
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

    let destination = switch alertRuleValue.destination {
    | Some(DiscordAlertDestination({guildId, channelId, template, clientId, roles})) => {
        discordAlertDestination: Some({
          guildId: guildId,
          channelId: channelId,
          clientId: Some(clientId),
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
      }
    | Some(SlackAlertDestination({channelId, incomingWebhookUrl})) => {
        slackAlertDestination: Some({channelId: channelId, incomingWebhookUrl: incomingWebhookUrl}),
        webPushAlertDestination: None,
        discordAlertDestination: None,
        twitterAlertDestination: None,
      }
    | Some(TwitterAlertDestination({userId, accessToken, template})) => {
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
      }
    | _ => raise(AlertDestinationRequired)
    }

    let (
      disabled,
      disabledReason,
      disabledExpiresAt,
    ) = switch alertRuleValue->AlertModal.Value.disabled {
    | Some(DestinationRateLimitExceeded(disabledExpiresAt)) => (
        Some(true),
        Some(#DESTINATION_RATE_LIMIT_EXCEEDED),
        disabledExpiresAt,
      )
    | Some(DestinationMissingAccess) => (Some(true), Some(#DESTINATION_MISSING_ACCESS), None)
    | Some(Snoozed) => (Some(true), Some(#SNOOZED), None)
    | _ => (None, None, None)
    }

    createAlertRuleMutation({
      input: {
        id: AlertModal.Value.id(alertRuleValue),
        accountAddress: switch authentication {
        | Authenticated({jwt: {accountAddress}}) => accountAddress
        | _ => Js.Exn.raiseError("Invalid state")
        },
        collectionSlug: alertRuleValue
        ->AlertModal.Value.collection
        ->Belt.Option.getExn
        ->AlertModal.CollectionOption.slugGet,
        contractAddress: alertRuleValue
        ->AlertModal.Value.collection
        ->Belt.Option.getExn
        ->AlertModal.CollectionOption.contractAddressGet,
        eventFilters: [
          priceEventFilter,
          propertiesEventFilter,
          quantityEventFilter,
          macroRelativeChangeEventFilter,
        ]->Belt.Array.keepMap(i => i),
        destination: destination,
        eventType: alertRuleValue->AlertModal.Value.eventType,
        disabled: disabled,
        disabledExpiresAt: disabledExpiresAt,
        disabledReason: disabledReason,
      },
    }) |> Js.Promise.then_(_ => {
      onCreated()
      Js.Promise.resolve()
    })
  }

  let handleActionClicked = () => {
    switch steps->Belt.Array.get(activeStepIdx)->Belt.Option.map(({label}) => label) {
    | Some("connect wallet") =>
      setIsActioning(_ => true)
      setCreateIntegrationError(_ => None)
      let _ = handleCreateOAuthIntegration() |> Js.Promise.then_(destinationResult => {
        setIsActioning(_ => false)
        switch destinationResult {
        | Ok(Some(destination)) =>
          setActiveStepIdx(idx => idx + 1)
          setAlertRuleValue(alertRuleValue => {
            ...alertRuleValue,
            destination: Some(destination),
          })
        | Ok(None) => setActiveStepIdx(idx => idx + 1)
        | Error(message) => setCreateIntegrationError(_ => Some(message))
        }
        Js.Promise.resolve()
      })
    | Some("select destination") => setActiveStepIdx(idx => idx + 1)
    | Some("configure alert") =>
      let validationResult = AlertModal.validate(alertRuleValue)
      setValidationError(_ => validationResult)
      switch validationResult {
      | None =>
        let _ = handleCreateAlertRule()
      | Some(_) => ()
      }
    | _ => ()
    }
  }

  <OAuthIntegrationDialog
    isOpen={isDialogOpen}
    onIsOpenChange={newIsDialogOpen => setIsDialogOpen(_ => newIsDialogOpen)}
    steps={steps}
    activeStepIdx={activeStepIdx}
    onActionClicked={handleActionClicked}
    isActioning={isActioning}
  />
}
