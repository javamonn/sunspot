@react.component
let make = (~onClickBuy, ~executionState) =>
  switch executionState {
  | OrderSection_Types.Buy =>
    <MaterialUi.Button
      onClick={_ => onClickBuy()}
      color=#Primary
      variant=#Contained
      fullWidth={true}
      classes={MaterialUi.Button.Classes.make(
        ~root=Cn.make(["flex-1", "lowercase", "font-bold", "py-4", "text-base"]),
        (),
      )}>
      {React.string("buy")}
    </MaterialUi.Button>
  | ClientPending =>
    <MaterialUi.Button
      color=#Primary
      variant=#Contained
      size=#Large
      fullWidth={true}
      classes={MaterialUi.Button.Classes.make(
        ~root=Cn.make(["flex-1", "lowercase", "font-bold", "py-4", "text-base"]),
        (),
      )}>
      {React.string("connecting...")}
      <MaterialUi.LinearProgress
        color=#Primary
        classes={MaterialUi.LinearProgress.Classes.make(
          ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
          (),
        )}
        variant=#Indeterminate
      />
    </MaterialUi.Button>
  | WalletConfirmPending =>
    <MaterialUi.Button
      color=#Primary
      variant=#Contained
      fullWidth={true}
      classes={MaterialUi.Button.Classes.make(
        ~root=Cn.make(["flex-1", "lowercase", "py-4"]),
        ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
        (),
      )}>
      {React.string("wallet confirm pending...")}
      <MaterialUi.LinearProgress
        color=#Primary
        classes={MaterialUi.LinearProgress.Classes.make(
          ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
          (),
        )}
        variant=#Indeterminate
      />
    </MaterialUi.Button>
  | TransactionCreated({transactionHash}) =>
    <a href={Services.URL.etherscanTransaction(transactionHash)} target="_blank">
      <MaterialUi.Button
        color=#Primary
        variant=#Contained
        fullWidth={true}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-2", "lowercase", "py-4"]),
          ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
          (),
        )}>
        {React.string("tx pending...")}
        <MaterialUi.LinearProgress
          color=#Primary
          classes={MaterialUi.LinearProgress.Classes.make(
            ~root=Cn.make(["absolute", "left-0", "bottom-0", "right-0"]),
            (),
          )}
          variant=#Indeterminate
        />
      </MaterialUi.Button>
    </a>
  | TransactionConfirmed({transactionHash}) =>
    <a href={Services.URL.etherscanTransaction(transactionHash)} target="_blank">
      <MaterialUi.Button
        fullWidth={true}
        variant=#Contained
        color=#Inherit
        startIcon={<Externals_MaterialUi_Icons.CheckCircleOutline />}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-1", "lowercase", "py-4", "bg-green-600"]),
          ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
          (),
        )}>
        <span style={ReactDOM.Style.make(~position="relative", ~top="2px", ())}>
          {React.string("tx confirmed")}
        </span>
      </MaterialUi.Button>
    </a>
  | TransactionFailed({transactionHash}) =>
    <a href={Services.URL.etherscanTransaction(transactionHash)} target="_blank">
      <MaterialUi.Button
        fullWidth={true}
        variant=#Contained
        startIcon={<Externals_MaterialUi_Icons.Error />}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["flex-1", "lowercase", "py-4", "bg-red-600"]),
          ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
          (),
        )}>
        <span style={ReactDOM.Style.make(~position="relative", ~top="2px", ())}>
          {React.string("tx failed")}
        </span>
      </MaterialUi.Button>
    </a>
  | InvalidOrder(reason) =>
    <MaterialUi.Button
      fullWidth={true}
      variant=#Contained
      startIcon={<Externals_MaterialUi_Icons.Error />}
      classes={MaterialUi.Button.Classes.make(
        ~root=Cn.make(["flex-1", "lowercase", "py-4", "bg-red-600"]),
        ~label=Cn.make(["text-lightPrimary", "font-bold", "text-base"]),
        (),
      )}>
      <span style={ReactDOM.Style.make(~position="relative", ~top="2px", ())}>
        {reason->Belt.Option.getWithDefault("invalid order")->React.string}
      </span>
    </MaterialUi.Button>
  }
