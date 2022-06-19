let percentFormatter = {
  open Externals_Webapi.Intl.NumberFormat
  make("en-US", params(~style="percent", ~maximumSignificantDigits=4))
}

@react.component
let make = (
  ~trait,
  ~collectionSlug,
  ~frequency=?,
  ~nameClassName=?,
  ~valueClassName=?,
  ~labelClassName=?,
) => {
  let traitUrl = Services.OpenSea.URL.makeAssetsUrl(
    ~collectionSlug,
    ~traitsFilter=[trait],
    ~eventType=#LISTING,
    ~sortBy=#PRICE,
    ~sortAscending=true,
    (),
  )

  <a href={traitUrl} target="_blank" className={Cn.make(["flex"])}>
    <MaterialUi.Button
      fullWidth={true}
      size=#Small
      variant=#Outlined
      classes={MaterialUi.Button.Classes.make(
        ~label=Cn.make([
          labelClassName->Belt.Option.getWithDefault(Cn.make(["p-1"])),
          "flex",
          "flex-col",
          "border-darkBorder",
        ]),
        (),
      )}>
      <span
        className={Cn.make([
          "text-darkSecondary",
          "lowercase",
          "text-center",
          "text-sm",
          "leading-none",
          "mb-1",
          nameClassName->Belt.Option.getWithDefault(""),
        ])}>
        {switch trait {
        | StringTrait({name}) | NumberTrait({name}) => React.string(name)
        }}
      </span>
      <span
        className={Cn.make([
          "text-darkPrimary",
          "text-center",
          "text-sm",
          "normal-case",
          "leading-none",
          "font-medium",
          valueClassName->Belt.Option.getWithDefault(""),
        ])}>
        {switch trait {
        | StringTrait({value}) => React.string(value)
        | NumberTrait({value}) => value->Belt.Float.toString->React.string
        }}
        {switch frequency {
        | Some(frequency) =>
          let formatted = Externals_Webapi.Intl.NumberFormat.format_(percentFormatter, frequency)
          React.string(` (${formatted})`)
        | None => React.null
        }}
      </span>
    </MaterialUi.Button>
  </a>
}
