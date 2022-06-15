let styles = %raw("require('./OAuthIntegrationDialog.module.css')")
type step = {
  label: string,
  actionLabel: string,
  element: React.element,
}

@react.component
let make = (~isOpen, ~onIsOpenChange, ~steps, ~activeStepIdx, ~onActionClicked, ~isActioning) => {
  <MaterialUi.Dialog
    _open={isOpen}
    onClose={(_, _) => onIsOpenChange(false)}
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
        activeStep={MaterialUi_Types.Number.int(activeStepIdx)}
        classes={MaterialUi.Stepper.Classes.make(~root=Cn.make(["mb-4", "px-0"]), ())}>
        {steps->Belt.Array.mapWithIndex((idx, {label}) =>
          <MaterialUi.Step key={label} completed={idx < activeStepIdx}>
            <MaterialUi.StepLabel> {React.string(label)} </MaterialUi.StepLabel>
          </MaterialUi.Step>
        )}
      </MaterialUi.Stepper>
      {steps
      ->Belt.Array.get(activeStepIdx)
      ->Belt.Option.map(({element}) => element)
      ->Belt.Option.getWithDefault(React.null)}
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions>
      <MaterialUi.Button
        variant=#Contained
        color=#Primary
        onClick={(_) => onActionClicked()}
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
          : steps
            ->Belt.Array.get(activeStepIdx)
            ->Belt.Option.map(({actionLabel}) => actionLabel)
            ->Belt.Option.getExn
            ->React.string}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
