let styles = %raw("require('./Containers_DiscordOnboarding.module.css')")
let steps = ["connect wallet", "configure alert", "select destination"]

@react.component
let make = () => {
  let {eth}: Contexts.Eth.t = React.useContext(Contexts.Eth.context)
  let {signIn, authentication}: Contexts.Auth.t = React.useContext(Contexts.Auth.context)
  let (isActioning, setIsActioning) = React.useState(() => false)
  let (isOpen, setIsOpen) = React.useState(() => true)
  let (activeStep, setActiveStep) = React.useState(() =>
    switch authentication {
    | Authenticated(_) => 1
    | _ => 0
    }
  )
  let (alertRuleValue, setAlertRuleValue) = React.useState(_ => AlertModal.Value.empty())
  let (validationError, setValidationError) = React.useState(_ => None)

  let onActionButtonClicked = _ => {
    if activeStep == 0 {
      setIsActioning(_ => true)
      let _ = signIn() |> Js.Promise.then_(authentication => {
        setIsActioning(_ => false)
        switch authentication {
        | Contexts.Auth.Authenticated(_) => setActiveStep(activeStep => activeStep + 1)
        | _ => ()
        }
        Js.Promise.resolve()
      })
    } else if activeStep == 1 {
      let validationResult = AlertModal.validate(alertRuleValue)
      setValidationError(_ => validationResult)
      switch validationResult {
      | None => setActiveStep(activeStep => activeStep + 1)
      | Some(_) => ()
      }
    } else {
      setActiveStep(activeStep => activeStep + 1)
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
    "connect wallet"
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
      <MaterialUi.DialogContent>
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
          ? <MaterialUi.Typography
              color=#Primary
              variant=#Body1
              classes={MaterialUi.Typography.Classes.make(~body1=Cn.make(["mb-16"]), ())}>
              {React.string(
                "sunspot is now installed within your discord guild. to start receiving alerts, connect your wallet to create an account.",
              )}
            </MaterialUi.Typography>
          : React.null}
        {activeStep === 1
          ? <AlertModal_DialogContent
              isExited={false}
              validationError={validationError}
              value={alertRuleValue}
              onChange={newValue => setAlertRuleValue(_ => newValue)}
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
