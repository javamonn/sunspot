let styles = %raw("require('./AlertModal.module.css')")

module CollectionOption = AlertModal_Types.CollectionOption
module Value = AlertModal_Value
module Utils = AlertModal_Utils

@react.component
let make = (
  ~isOpen,
  ~onClose,
  ~onExited=?,
  ~value,
  ~accountSubscriptionType,
  ~alertCount,
  ~updatingValue=?,
  ~destinationOptions,
  ~onChange,
  ~onAction,
  ~actionLabel,
  ~title,
  ~renderOverflowActionMenuItems=?,
) => {
  let (isExited, setIsExited) = React.useState(_ => isOpen)
  let (validationError, setValidationError) = React.useState(_ => None)
  let (isActioning, setIsActioning) = React.useState(_ => false)
  let {openDialog: openAccountSubscriptionDialog} = React.useContext(
    Contexts_AccountSubscriptionDialog_Context.context,
  )

  let _ = React.useEffect1(() => {
    if isOpen {
      setIsExited(_ => false)
    }
    None
  }, [isOpen])

  let handleExited = () => {
    setIsExited(_ => true)
    setValidationError(_ => None)
    onExited->Belt.Option.forEach(fn => fn())
  }

  let handleAction = () => {
    let executeAction = () => {
      setIsActioning(_ => true)
      setValidationError(_ => None)
      let _ =
        onAction()
        |> Js.Promise.then_(_ => {
          setIsActioning(_ => false)
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(_ => {
          setIsActioning(_ => false)
          Js.Promise.resolve()
        })
    }
    switch AlertModal_Validate.execute(
      ~accountSubscriptionType,
      ~alertCount,
      ~updatingValue,
      ~value,
    ) {
    | None => executeAction()
    | Some(AccountSubscriptionRequired({message, requiredAccountSubscriptionType})) =>
      let _ =
        message->React.string->Js.Option.some->openAccountSubscriptionDialog
        |> Js.Promise.then_(newSubscriptionType => {
          switch (requiredAccountSubscriptionType, newSubscriptionType) {
          | (#TELESCOPE, Some(#TELESCOPE))
          | (#OBSERVATORY, Some(#OBSERVATORY))
          | (#TELESCOPE, Some(#OBSERVATORY)) =>
            let _ = executeAction()
          | _ => setValidationError(_ => Some(message))
          }
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(error => {
          Services.Logger.promiseError("AlertModal handleAction", "error", error)
          let _ = setValidationError(_ => Some(message))
          Js.Promise.resolve()
        })
    | Some(InvalidInput(s)) => setValidationError(_ => Some(s))
    }
  }

  <MaterialUi.Dialog
    _open={isOpen}
    onClose={(_, _) => onClose()}
    onExited={_ => handleExited()}
    classes={MaterialUi.Dialog.Classes.make(
      ~paper=Cn.make([
        styles["dialogPaper"],
        "sm:w-full",
        "sm:h-full",
        "sm:max-w-full",
        "sm:max-h-full",
        "sm:m-0",
        "sm:rounded-none",
      ]),
      (),
    )}>
    <MaterialUi.DialogTitle
      disableTypography=true
      classes={MaterialUi.DialogTitle.Classes.make(
        ~root=Cn.make([
          "flex",
          "justify-between",
          "items-center",
          "sm:px-4",
          "sm:py-4",
          "border-b",
          "border-solid",
          "border-darkBorder",
        ]),
        (),
      )}>
      <div className={Cn.make(["flex", "flex-row", "items-center"])}>
        <MaterialUi.IconButton
          onClick={_ => onClose()}
          size=#Small
          classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["mr-4"]), ())}>
          <Externals.MaterialUi_Icons.Close />
        </MaterialUi.IconButton>
        <MaterialUi.Typography
          color=#Primary
          variant=#H6
          classes={MaterialUi.Typography.Classes.make(~root=Cn.make(["leading-none", "mt-1"]), ())}>
          {React.string(title)}
        </MaterialUi.Typography>
      </div>
      <div className={Cn.make(["flex", "flex-row", "items-center"])}>
        {value
        ->Value.disabled
        ->Belt.Option.map(disabled => {
          let title = switch disabled {
          | Snoozed => "alert has been disabled."
          | Satisfied => "alert has been satisfied and automatically disabled."
          | DestinationMissingAccess =>  "alert has been disabled due to being unable to connect to the destination. try reconnecting or adjusting permissions and re-enable."
          | DestinationRateLimitExceeded(
              _,
            ) => "alert has been disabled due to a ratelimit and will automatically re-enable after a period of time."
          | AccountSubscriptionAlertLimitExceeded => "alert has been disabled due to exceeding your account alert limit. upgrade your account for increased limits."
          | AccountSubscriptionMissingFunctionality => "alert has been disabled due to exceeding your account functionality. upgrade your account for advanced functionality."
          }

          <MaterialUi.Tooltip title={React.string(title)}>
            <Externals.MaterialUi_Icons.Error
              className={Cn.make(["w-6", "h-6", "mr-2", "text-red-400"])}
            />
          </MaterialUi.Tooltip>
        })
        ->Belt.Option.getWithDefault(React.null)}
        {renderOverflowActionMenuItems
        ->Belt.Option.map(renderOverflowActionMenuItems =>
          <IconMenu
            icon={<Externals.MaterialUi_Icons.MoreVert />}
            renderItems={renderOverflowActionMenuItems}
            anchorOrigin={
              open MaterialUi.Menu
              AnchorOrigin.make(
                ~horizontal=Horizontal.enum(Horizontal_enum.left),
                ~vertical=Vertical.enum(Vertical_enum.bottom),
                (),
              )
            }
            menuClasses={MaterialUi.Menu.Classes.make(~paper=Cn.make(["bg-gray-100"]), ())}
          />
        )
        ->Belt.Option.getWithDefault(React.null)}
      </div>
    </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(
        ~root=Cn.make(["flex", "flex-col", "sm:px-4", "sm:py-4", "mt-4", "sm:mt-0"]),
        (),
      )}>
      <AlertModal_DialogContent
        value={value}
        isExited={isExited}
        onChange={onChange}
        validationError={validationError}
        destinationOptions={destinationOptions}
      />
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions
      classes={MaterialUi.DialogActions.Classes.make(
        ~root=Cn.make([
          "mt-8",
          "sm:mt-0",
          "border-t",
          "border-solid",
          "border-darkBorder",
          "sm:py-4",
          "sm:px-4",
        ]),
        (),
      )}>
      <MaterialUi.Button
        variant=#Text
        color=#Primary
        disabled={isActioning}
        onClick={_ => onClose()}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["mr-2"]),
          ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
          (),
        )}>
        {React.string("cancel")}
      </MaterialUi.Button>
      <MaterialUi.Button
        variant=#Contained
        color=#Primary
        disabled={isActioning}
        onClick={_ => handleAction()}
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["normal-case", "leading-none", "py-1", "w-16"]),
          (),
        )}>
        {isActioning
          ? <MaterialUi.CircularProgress size={MaterialUi.CircularProgress.Size.int(18)} />
          : React.string(actionLabel)}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
