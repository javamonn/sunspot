open Containers_OAuthIntegration_GraphQL

exception SignInFailed
exception InvalidState

type integrationParams =
  | Discord({code: string, guildId: string, permissions: int, redirectUri: string})
  | Slack({code: string, redirectUri: string})
  | Twitter({code: string, redirectUri: string})

let integrationDisplayName = integrationParams =>
  switch integrationParams {
  | Discord(_) => "discord"
  | Slack(_) => "slack"
  | Twitter(_) => "twitter"
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
          onChange={newValue => setAlertRuleValue(_ => newValue)}
          destinationOptions={createSlackOAuthIntegrationMutationResultData
          ->Belt.Option.map(data => [
            AlertRule_Destination.Option.SlackAlertDestinationOption({
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
          onChange={newValue => setAlertRuleValue(_ => newValue)}
          destinationOptions={createTwitterOAuthIntegrationMutationResultData
          ->Belt.Option.map(data => [
            AlertRule_Destination.Option.TwitterAlertDestinationOption({
              userId: data.twitterIntegration.user.id,
              username: data.twitterIntegration.user.username,
              profileImageUrl: data.twitterIntegration.user.profileImageUrl,
              accessToken: {
                accessToken: data.twitterIntegration.accessToken.accessToken,
                refreshToken: data.twitterIntegration.accessToken.refreshToken,
                scope: data.twitterIntegration.accessToken.scope,
                expiresAt: data.twitterIntegration.accessToken.expiresAt,
                tokenType: data.twitterIntegration.accessToken.tokenType,
              },
            }),
          ])
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
          | AlertRule_Destination.Value.DiscordAlertDestination({channelId}) =>
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
              destination: AlertRule_Destination.Value.DiscordAlertDestination({
                guildId: data.discordIntegration.guildId,
                channelId: newValue->DiscordIntegrationChannelRadioGroup.id,
              }),
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
          onChange={newValue => setAlertRuleValue(_ => newValue)}
          destinationOptions={createDiscordOAuthIntegrationMutationResultData
          ->Belt.Option.map(data =>
            data.discordIntegration.channels->Belt.Array.map(
              channel => AlertRule_Destination.Option.DiscordAlertDestinationOption({
                channelId: channel.id,
                channelName: channel.name,
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
  let (isActioning, setIsActioning) = React.useState(() => false)
  let (step0BodyText, _) = React.useState(() =>
    switch authentication {
    | Authenticated(_) =>
      `sunspot is now installed within your ${integrationDisplayName(
          params,
        )} server. to start receiving alerts, click next to connect your account.`
    | _ =>
      `sunspot is now installed within your ${integrationDisplayName(
          params,
        )} server. to start receiving alerts, connect your wallet to create an account.`
    }
  )
  let (alertRuleValue, setAlertRuleValue) = React.useState(_ => AlertModal.Value.empty())

  let (createAlertRuleMutation, _) = Mutation_CreateAlertRule.use()
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

  let handleCreateOAuthIntegration = () => {
    let executeMutation = () => {
      let mutation = switch params {
      | Discord({code, guildId, permissions, redirectUri}) =>
        createDiscordOAuthIntegrationMutation({
          input: {
            code: code,
            guildId: guildId,
            permissions: permissions,
            redirectUri: redirectUri,
          },
        }) |> Js.Promise.then_(result =>
          /* * discord alert destination is set in step 2 * */
          result->Belt.Result.map(result => None)->Js.Promise.resolve
        )
      | Slack({code, redirectUri}) =>
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
            AlertRule_Destination.Value.SlackAlertDestination({
              channelId: result.data.slackIntegration.channelId,
              incomingWebhookUrl: result.data.slackIntegration.incomingWebhookUrl,
            }),
          ))
          ->Js.Promise.resolve
        )
      | Twitter({code, redirectUri}) =>
        createTwitterOAuthIntegrationMutation({
          input: {
            code: code,
            redirectUri: redirectUri,
          },
        }) |> Js.Promise.then_(result => {
          result
          ->Belt.Result.map((
            result: ApolloClient__React_Types.FetchResult.t__ok<
              Mutation_CreateTwitterOAuthIntegration.Mutation_CreateTwitterOAuthIntegration_inner.t,
            >,
          ) => {
            let data = result.data.twitterIntegration
            Some(
              AlertRule_Destination.Value.TwitterAlertDestination({
                userId: data.user.id,
                accessToken: {
                  accessToken: data.accessToken.accessToken,
                  refreshToken: data.accessToken.refreshToken,
                  expiresAt: data.accessToken.expiresAt,
                  scope: data.accessToken.scope,
                  tokenType: data.accessToken.tokenType,
                },
              }),
            )
          })
          ->Js.Promise.resolve
        })
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
              )} server. try again or contact us for support.`,
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
              )} server. try again or contact us for support.`,
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
            "an error occurred while connecting your wallet. try again or contact us for support.",
          ),
        )
      })
    }
  }

  let handleCreateAlertRule = () => {
    open Mutation_CreateAlertRule
    setIsActioning(_ => true)

    let priceEventFilter =
      alertRuleValue
      ->AlertModal.Value.priceRule
      ->Belt.Option.flatMap(rule => {
        let direction = switch CreateAlertRule_Price.modifier(rule) {
        | ">" => Some(#ALERT_ABOVE)
        | "<" => Some(#ALERT_BELOW)
        | _ => None
        }
        let value =
          rule
          ->CreateAlertRule_Price.value
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
    let propertiesEventFilter =
      alertRuleValue
      ->AlertModal.Value.propertiesRule
      ->Belt.Option.map(rule => {
        let attributeInputs = rule->Belt.Array.map(a =>
          switch a->CreateAlertRule_Properties.Value.value {
          | StringValue({value}) => {
              openSeaAssetStringAttribute: Some({
                value: value,
                traitType: a->CreateAlertRule_Properties.Value.traitType,
              }),
              openSeaAssetNumberAttribute: None,
            }
          | NumberValue({value}) => {
              openSeaAssetNumberAttribute: Some({
                value: value,
                traitType: a->CreateAlertRule_Properties.Value.traitType,
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

    let destination = switch alertRuleValue.destination {
    | DiscordAlertDestination({guildId, channelId}) => {
        discordAlertDestination: Some({guildId: guildId, channelId: channelId}),
        webPushAlertDestination: None,
        slackAlertDestination: None,
        twitterAlertDestination: None,
      }
    | SlackAlertDestination({channelId, incomingWebhookUrl}) => {
        slackAlertDestination: Some({channelId: channelId, incomingWebhookUrl: incomingWebhookUrl}),
        webPushAlertDestination: None,
        discordAlertDestination: None,
        twitterAlertDestination: None,
      }
    | TwitterAlertDestination({userId, accessToken}) => {
        discordAlertDestination: None,
        webPushAlertDestination: None,
        slackAlertDestination: None,
        twitterAlertDestination: Some({
          userId: userId,
          accessToken: {
            accessToken: accessToken.accessToken,
            refreshToken: accessToken.refreshToken,
            tokenType: accessToken.tokenType,
            scope: accessToken.scope,
            expiresAt: accessToken.expiresAt,
          },
        }),
      }
    | WebPushAlertDestination => {
        webPushAlertDestination: None,
        discordAlertDestination: None,
        slackAlertDestination: None,
        twitterAlertDestination: None,
      }
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
        eventFilters: [priceEventFilter, propertiesEventFilter]->Belt.Array.keepMap(i => i),
        destination: destination,
        eventType: switch alertRuleValue->AlertModal.Value.eventType {
        | #listing => #LISTING
        | #sale => #SALE
        },
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
            destination: destination,
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
