@react.component
let make = (
  ~createdAt,
  ~now,
  ~assetName,
  ~assetTokenId,
  ~collectionName,
  ~collectionSlug,
  ~price,
  ~paymentTokenImageUrl,
  ~paymentTokenDecimals,
  ~eventLabel,
  ~action,
  ~openSeaAssetAttributes,
  ~alertRule,
) => {
  let relativeListingTime =
    createdAt
    ->Belt.Option.map(createdTime => {
      let formatted = Externals.DateFns.formatDistanceStrict(
        createdTime *. 1000.0,
        now,
        Externals.DateFns.formatDistanceStrictOptions(),
      )

      let replaced =
        formatted
        ->Js.String2.replace(" seconds", "s")
        ->Js.String2.replace(" minutes", "m")
        ->Js.String2.replace(" hours", "h")
        ->Js.String2.replace(" months", "mo")
        ->Js.String2.replace(" years", "y")

      replaced
    })
    ->Belt.Option.getWithDefault("now")

  <div
    className={Cn.make([
      "p-3",
      "border-t",
      "border-b",
      "border-r",
      "border-solid",
      "border-darkBorder",
      "rounded",
      "flex-1",
      "grid",
      "xs:flex",
      "overflow-hidden"
    ])}
    style={ReactDOM.Style.make(~gridTemplateColumns="1fr 2fr", ())}>
    <div className={Cn.make(["flex", "flex-col", "justify-between", "flex-1", "overflow-hidden"])}>
      <div className={Cn.make(["flex", "flex-col", "flex-1"])}>
        <h2
          className={Cn.make([
            "text-darkPrimary",
            "text-lg",
            "whitespace-nowrap",
            "overflow-x-hidden",
            "truncate",
            "xs:hidden",
          ])}>
          {React.string(`${eventLabel}: `)}
          {assetName->Belt.Option.getWithDefault(`#${assetTokenId}`)->React.string}
        </h2>
        <div className={Cn.make(["hidden", "xs:flex", "flex-row", "justify-between", "mb-2"])}>
          <h3
            className={Cn.make([
              "text-darkSecondary",
              "text-xs",
              "leading-none",
              "whitespace-pre",
            ])}>
            {React.string(eventLabel)}
          </h3>
          <span className={Cn.make(["text-darkSecondary", "text-xs", "leading-none"])}>
            {React.string(relativeListingTime)}
          </span>
        </div>
        <h2
          className={Cn.make([
            "text-darkPrimary",
            "text-base",
            "hidden",
            "xs:block",
            "leading-none",
            "whitespace-pre",
            "truncate",
            "mb-1",
          ])}>
          {assetName->Belt.Option.getWithDefault(`#${assetTokenId}`)->React.string}
        </h2>
        <div
          className={Cn.make([
            "flex-row",
            "flex",
            "leading-none",
            "flex-shrink-0",
            "whitespace-nowrap",
          ])}>
          <span
            className={Cn.make(["text-darkSecondary", "whitespace-pre", "text-base", "xs:hidden"])}>
            {React.string(`${relativeListingTime} • `)}
          </span>
          <h3 className={Cn.make(["text-darkSecondary", "text-base", "xs:hidden"])}>
            {collectionName->Belt.Option.getWithDefault(collectionSlug)->React.string}
          </h3>
        </div>
      </div>
      <div className={Cn.make(["flex", "flex-row", "space-x-4"])}>
        {action}
        <h1
          className={Cn.make(["text-darkPrimary", "text-xl", "font-bold", "leading-none"])}
          style={ReactDOM.Style.make(~position="relative", ~top="1px", ())}>
          <img
            src={paymentTokenImageUrl}
            className={Cn.make(["mb-1", "mr-1", "inline"])}
            style={ReactDOM.Style.make(~height="18px", ())}
          />
          {price
          ->Externals.Ethers.Utils.parseUnitsWithDecimals(0)
          ->Externals.Ethers.Utils.formatUnitsWithDecimals(paymentTokenDecimals)
          ->React.string}
        </h1>
      </div>
    </div>
    <div className={Cn.make(["flex", "flex-col", "overflow-x-hidden", "md:hidden"])}>
      <EventsListItem_Attributes openSeaAsset={openSeaAssetAttributes} />
      <EventsListItem_EventFilters alertRule={alertRule} />
    </div>
  </div>
}
