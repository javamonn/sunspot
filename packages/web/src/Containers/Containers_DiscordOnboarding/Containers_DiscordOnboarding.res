let styles = %raw("require('./Containers_DiscordOnboarding.module.css')")

let steps = ["connect wallet", "select destination", "configure alert"]

exception SignInFailed
exception InvalidState

module AlertRule = QueryRenderers_Alerts_GraphQL.Query_AlertRulesByAccountAddress.AlertRule
module Mutation_CreateDiscordIntegration = %graphql(`
  mutation CreateDiscordIntegration($input: CreateDiscordIntegrationInput!) {
    discordIntegration: createDiscordIntegration(input: $input) {
      guildId
      iconUrl
      name
      channels {
        id
        name
      }
    }
  }
`)
module Mutation_CreateAlertRule = %graphql(`
  mutation CreateAlertRule($input: CreateAlertRuleInput!) {
    alertRule: createAlertRule(input: $input) {
      ...AlertRule
    }
  }
`)

@react.component
let make = (~code, ~guildId, ~permissions, ~redirectUri, ~onCreated) => {
  let {eth}: Contexts.Eth.t = React.useContext(Contexts.Eth.context)
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let (isActioning, setIsActioning) = React.useState(() => false)
  let (isOpen, setIsOpen) = React.useState(() => true)
  let (activeStep, setActiveStep) = React.useState(() => 0)
  let (alertRuleValue, setAlertRuleValue) = React.useState(_ => AlertModal.Value.empty())
  let (validationError, setValidationError) = React.useState(_ => None)
  let (createDiscordIntegrationError, setCreateDiscordIntegrationError) = React.useState(_ => None)
  let (discordIntegrationChannelIdValue, setDiscordIntegrationChannelIdValue) = React.useState(_ =>
    None
  )
  let (step0BodyText, _) = React.useState(() =>
    switch authentication {
    | Authenticated(
        _,
      ) => "sunspot is now installed within your discord server. to start receiving alerts, click next to connect your account."
    | _ => "sunspot is now installed within your discord server. to start receiving alerts, connect your wallet to create an account."
    }
  )

  let (
    createDiscordIntegrationMutation,
    createDiscordIntegrationMutationResult,
  ) = Mutation_CreateDiscordIntegration.use()
  let (createAlertRuleMutation, _) = Mutation_CreateAlertRule.use()
  let discordIntegration =
    createDiscordIntegrationMutationResult.data->Belt.Option.map(d => d.discordIntegration)
  let discordDestinationOptions =
    discordIntegration
    ->Belt.Option.map(discordIntegration =>
      discordIntegration.channels->Belt.Array.map(channel => {
        AlertRule_Destination.Option.channelId: channel.id,
        channelName: channel.name,
        guildId: discordIntegration.guildId,
        guildName: discordIntegration.name,
        guildIconUrl: discordIntegration.iconUrl,
      })
    )
    ->Belt.Option.getWithDefault([])

  let handleCreateDiscordIntegration = () => {
    let execute = () =>
      createDiscordIntegrationMutation({
        input: {
          code: code,
          guildId: guildId,
          permissions: permissions,
          redirectUri: redirectUri,
        },
      })
      |> Js.Promise.then_(result => {
        setIsActioning(_ => false)
        let _ = switch result {
        | Ok(_) => setActiveStep(_ => 1)
        | Error(e) =>
          Services.Logger.apolloError(
            "Containers_DiscordOnboarding",
            "handleCreateDiscordIntegration",
            e,
          )
          setCreateDiscordIntegrationError(_ => Some(
            "an error occurred while connecting your account to your Discord server. try again or contact us for support.",
          ))
        }
        Js.Promise.resolve()
      })
      |> Js.Promise.catch(err => {
        Services.Logger.promiseError(
          "Containers_DiscordOnboarding",
          "handleCreateDiscordIntegration",
          err,
        )
        setCreateDiscordIntegrationError(_ => Some(
          "an error occurred while connecting your account to your Discord server. try again or contact us for support.",
        ))
        setIsActioning(_ => false)
        Js.Promise.resolve()
      })

    setIsActioning(_ => true)
    setCreateDiscordIntegrationError(_ => None)
    switch authentication {
    | Authenticated(_) => execute()
    | _ =>
      signIn()
      |> Js.Promise.then_(authentication => {
        switch authentication {
        | Contexts.Auth.Authenticated(_) => execute()
        | _ => Js.Promise.reject(SignInFailed)
        }
      })
      |> Js.Promise.catch(err => {
        Services.Logger.promiseError(
          "Containers_DiscordOnboarding",
          "handleCreateDiscordIntegration",
          err,
        )
        setIsActioning(_ => false)
        setCreateDiscordIntegrationError(_ => Some(
          "an error occurred while connecting your wallet. try again or contact us for support.",
        ))
        Js.Promise.resolve()
      })
    }
  }

  let handleCreateAlertRule = () => {
    switch (discordIntegration, discordIntegrationChannelIdValue) {
    | (Some(discordIntegration), Some(discordIntegrationChannelIdValue)) =>
      open Mutation_CreateAlertRule

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
      let destination = {
        webPushAlertDestination: None,
        discordAlertDestination: switch alertRuleValue.destination {
        | AlertRule_Destination.Value.WebPushAlertDestination => None
        | DiscordAlertDestination({guildId, channelId}) =>
          Some({guildId: guildId, channelId: channelId})
        },
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
          eventType: Some(#LISTING)
        },
      }) |> Js.Promise.then_(_ => {
        onCreated()
        Js.Promise.resolve()
      })
    | _ => Js.Promise.resolve()
    }
  }

  let onActionButtonClicked = _ => {
    if activeStep == 0 {
      let _ = handleCreateDiscordIntegration()
    } else if activeStep == 1 {
      setAlertRuleValue(alertRule =>
        switch (discordIntegration, discordIntegrationChannelIdValue) {
        | (Some(discordIntegration), Some(discordIntegrationChannelIdValue)) => {
            ...alertRule,
            destination: AlertRule_Destination.Value.DiscordAlertDestination({
              guildId: discordIntegration.guildId,
              channelId: discordIntegrationChannelIdValue->DiscordIntegrationChannelRadioGroup.id,
            }),
          }
        | _ => alertRule
        }
      )
      setActiveStep(activeStep => activeStep + 1)
    } else if activeStep == 2 {
      let validationResult = AlertModal.validate(alertRuleValue)
      setValidationError(_ => validationResult)
      switch validationResult {
      | None =>
        setIsActioning(_ => true)
        let _ = handleCreateAlertRule()
      | Some(_) => ()
      }
    }
  }

  let isActionButtonEnabled = if activeStep == 0 {
    true
  } else if activeStep == 1 {
    true
  } else {
    true
  }
  let actionLabel = if activeStep == 0 {
    switch authentication {
    | Authenticated(_) => "connect account"
    | _ => "connect wallet"
    }
  } else if activeStep == 1 {
    "next"
  } else {
    "create alert"
  }

  <>
    <MaterialUi.Dialog
      _open={isOpen}
      onClose={(_, _) => setIsOpen(_ => false)}
      maxWidth={MaterialUi.Dialog.MaxWidth.xl}
      classes={MaterialUi.Dialog.Classes.make(~paper=styles["dialogPaper"], ())}
      disableBackdropClick={true}
      disableEscapeKeyDown={true}>
      <MaterialUi.DialogTitle disableTypography=true>
        <MaterialUi.Typography
          color=#Primary
          variant=#H6
          classes={MaterialUi.Typography.Classes.make(~root=Cn.make(["leading-none"]), ())}>
          {React.string("install sunspot")}
        </MaterialUi.Typography>
      </MaterialUi.DialogTitle>
      <MaterialUi.DialogContent
        classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["flex", "flex-col"]), ())}>
        <MaterialUi.Stepper
          activeStep={MaterialUi_Types.Number.int(activeStep)}
          classes={MaterialUi.Stepper.Classes.make(~root=Cn.make(["mb-4", "px-0"]), ())}>
          {steps->Belt.Array.mapWithIndex((idx, label) =>
            <MaterialUi.Step key={label} completed={idx < activeStep}>
              <MaterialUi.StepLabel> {React.string(label)} </MaterialUi.StepLabel>
            </MaterialUi.Step>
          )}
        </MaterialUi.Stepper>
        {activeStep === 0
          ? <>
              {createDiscordIntegrationError
              ->Belt.Option.map(error =>
                <MaterialUi_Lab.Alert
                  severity=#Error
                  classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
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
          : React.null}
        {switch discordIntegration {
        | Some(discordIntegration) if activeStep == 1 => <>
            <MaterialUi.Typography
              color=#Primary
              variant=#Body1
              classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-10"]), ())}>
              {React.string("select the channel within ")}
              <span className={Cn.make(["font-bold"])}>
                {React.string(discordIntegration.name)}
              </span>
              {React.string(" that will receive alerts:")}
            </MaterialUi.Typography>
            <DiscordIntegrationChannelRadioGroup
              guildName={discordIntegration.name}
              guildIconUrl=?{discordIntegration.iconUrl}
              options={discordIntegration.channels->Belt.Array.map(c => {
                DiscordIntegrationChannelRadioGroup.id: c.id,
                name: c.name,
              })}
              value={discordIntegrationChannelIdValue}
              onChange={newValue => setDiscordIntegrationChannelIdValue(_ => Some(newValue))}
            />
          </>
        | _ => React.null
        }}
        {activeStep === 2
          ? <AlertModal_DialogContent
              isExited={false}
              validationError={validationError}
              value={alertRuleValue}
              onChange={newValue => setAlertRuleValue(_ => newValue)}
              discordDestinationOptions={discordDestinationOptions}
              destinationDisabled={true}
            />
          : React.null}
      </MaterialUi.DialogContent>
      <MaterialUi.DialogActions>
        <MaterialUi.Button
          variant=#Contained
          color=#Primary
          disabled={!isActionButtonEnabled}
          onClick={onActionButtonClicked}
          classes={MaterialUi.Button.Classes.make(
            ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
            (),
          )}>
          {isActioning
            ? <MaterialUi.CircularProgress
                size={MaterialUi.CircularProgress.Size.int(18)}
                color={#Secondary}
                classes={MaterialUi.CircularProgress.Classes.make(~root=Cn.make(["mx-12"]), ())}
              />
            : React.string(actionLabel)}
        </MaterialUi.Button>
      </MaterialUi.DialogActions>
    </MaterialUi.Dialog>
  </>
}
