@react.component
let make = (~value, ~onChange) => {
  let handleFloorPriceRuleChange = newFloorPriceChangeRule =>
    onChange(value => {
      ...value,
      AlertModal_Value.floorPriceChangeRule: Some(newFloorPriceChangeRule),
    })

  let handlePriceRuleChange = priceRule => {
    onChange(value => {
      ...value,
      priceRule: priceRule,
    })
  }

  <>
    <AlertRule_Accordion
      summaryIcon={<Externals_MaterialUi_Icons.AssessmentOutlined
        style={ReactDOM.Style.make(~opacity="0.42", ())}
      />}
      summaryTitle={React.string("relative change rule")}
      summaryDescription={React.string(
        "satisfies when floor price changes by a percent relative to current",
      )}
      renderDetails={(~expanded) =>
        <AlertRule_MacroRelativeFloorPriceChange
          value={value->AlertModal_Value.floorPriceChangeRule} onChange={handleFloorPriceRuleChange}
        />}
    />
    <AlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<MaterialUi.Typography
        variant=#H5
        classes={MaterialUi.Typography.Classes.make(
          ~h5=Cn.make(["leading-none", "text-darkSecondary"]),
          (),
        )}>
        {React.string(`Ξ`)}
      </MaterialUi.Typography>}
      summaryTitle={React.string("absolute change rule")}
      summaryDescription={React.string("satisfies when floor price crosses a threshold")}
      renderDetails={(~expanded) =>
        <div className={Cn.make(["flex", "flex-col"])}>
          <InfoAlert
            text={React.string(
              "alert rule will automatically disable once an absolute change rule is satisfied.",
            )}
            className={Cn.make(["mb-4"])}
          />
          <AlertRule_Price
            ruleLabel="floor price"
            value=?{value->AlertModal_Value.priceRule}
            onChange={handlePriceRuleChange}
            accordionExpanded={expanded}
          />
        </div>}
    />
  </>
}
