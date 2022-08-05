type plan = {
  title: string,
  subtitle: string,
  features: array<string>,
}

let plans = [
  {
    title: "stargazer",
    subtitle: `Ξ0 / unlimited`,
    features: [
      "3 alerts",
      "quickbuy",
      "2.5% quickbuy fee",
      "push, discord, and slack alert destinations",
    ],
  },
  {
    title: "telescope",
    subtitle: `Ξ0.033 / 30 days`,
    features: ["all stargazer features", "15 alerts", "1% quickbuy fee"],
  },
  {
    title: "observatory",
    subtitle: `Ξ0.099 / 90 days`,
    features: [
      "all telescope features",
      "unlimited alerts",
      "0% quickbuy fee",
      "twitter alert destination",
      "customize alert text and formatting",
    ],
  },
]

@react.component
let make = (
  ~accountSubscription: option<Query_AccountSubscription.GraphQL.AccountSubscription.t>=?,
  ~isOpen,
  ~onClose,
  ~onClickPurchase,
  ~pendingPurchase,
  ~header=?,
) => {
  <MaterialUi.Dialog
    _open={isOpen}
    onClose={(_, _) => onClose()}
    maxWidth={MaterialUi.Dialog.MaxWidth.lg}
    classes={MaterialUi.Dialog.Classes.make(
      ~paper=Cn.make([
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
      disableTypography={true}
      classes={MaterialUi.DialogTitle.Classes.make(
        ~root=Cn.make([
          "px-6",
          "pb-0",
          "leading-none",
          "flex",
          "items-center",
          "flex-row",
          "md:px-4",
          "md:pb-4",
          "md:border",
          "md:border-b",
          "md:border-darkBorder",
        ]),
        (),
      )}>
      <MaterialUi.IconButton
        onClick={_ => onClose()}
        size=#Small
        classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["mr-4"]), ())}>
        <Externals.MaterialUi_Icons.Close />
      </MaterialUi.IconButton>
      <MaterialUi.Typography
        color=#Primary
        variant=#H6
        classes={MaterialUi.Typography.Classes.make(~root=Cn.make(["leading-none"]), ())}>
        {React.string("upgrade account")}
      </MaterialUi.Typography>
    </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(
        ~root=Cn.make(["font-mono", "p-6", "md:p-4"]),
        (),
      )}>
      {header
      ->Belt.Option.map(header =>
        <div
          className={Cn.make([
            "flex",
            "flex-row",
            "p-6",
            "mb-6",
            "text-darkPrimary",
            "rounded",
            "items-center",
            "sm:p-4",
          ])}
          style={ReactDOM.Style.make(
            ~backgroundColor="rgba(230, 74, 25, 0.72)",
            ~border="solid 1px rgba(230, 74, 25, 0.92)",
            (),
          )}>
          <Externals_MaterialUi_Icons.Error
            className={Cn.make(["w-6", "h-6", "mr-6"])}
            style={ReactDOM.Style.make(~opacity="0.92", ())}
          />
          {header}
        </div>
      )
      ->Belt.Option.getWithDefault(React.null)}
      {accountSubscription
      ->Belt.Option.map(({ttl, type_}) => {
        let displayTTL = Externals.DateFns.formatDistanceStrict(
          ttl->Js.Json.decodeNumber->Belt.Option.getExn *. 1000.0,
          Js.Date.now(),
          Externals.DateFns.formatDistanceStrictOptions(~unit_="day", ~roundingMethod="ceil", ()),
        )
        let displayType = switch type_ {
        | #TELESCOPE => "telescope"
        | #OBSERVATORY => "observatory"
        | #FutureAddedValue(v) => v
        }

        <div
          className={Cn.make([
            "border",
            "border-solid",
            "border-darkBorder",
            "rounded",
            "mb-6",
            "p-4",
          ])}>
          {React.string("you have " ++ displayTTL ++ " of ")}
          <span className={Cn.make(["underline", "font-bold"])}> {React.string(displayType)} </span>
          {React.string(
            " access remaining. additional access purchased will be added to your balance.",
          )}
        </div>
      })
      ->Belt.Option.getWithDefault(React.null)}
      <div
        className={Cn.make([
          "flex",
          "flex-row",
          "space-x-10",
          "md:flex-col",
          "md:space-x-0",
          "md:space-y-6",
        ])}>
        {plans
        ->Belt.Array.map(({title, subtitle, features}) => {
          let isPending = switch pendingPurchase {
          | Some(#TELESCOPE) if title === "telescope" => true
          | Some(#OBSERVATORY) if title === "observatory" => true
          | _ => false
          }
          let disabled = title === "stargazer" || Js.Option.isSome(pendingPurchase)
          let onClick = () =>
            switch title {
            | "telescope" => onClickPurchase(#TELESCOPE)
            | "observatory" => onClickPurchase(#OBSERVATORY)
            | _ => ()
            }
          let labelText = if title == "stargazer" {
            "free"
          } else if isPending {
            "purchasing..."
          } else {
            "purchase"
          }

          <AccountSubscriptionCard
            title={title}
            subtitle={subtitle}
            features={features}
            disabled={disabled}
            onClick={onClick}
            labelText={labelText}
            isActioning={isPending}
          />
        })
        ->React.array}
      </div>
    </MaterialUi.DialogContent>
  </MaterialUi.Dialog>
}
