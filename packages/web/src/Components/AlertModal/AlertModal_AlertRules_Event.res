open AlertModal_Value
open AlertModal_Types

@react.component
let make = (
  ~value,
  ~collectionAggregateAttributes,
  ~isLoadingCollectionAggregateAttributes,
  ~onChange,
) => {
  let handlePriceRuleChange = priceRule => {
    onChange(value => {
      ...value,
      priceRule: priceRule,
    })
  }
  let handlePropertiesRuleChange = propertiesRule =>
    onChange(value => {
      ...value,
      propertiesRule: propertiesRule,
    })
  let handleQuantityRuleChange = quantityRule => {
    onChange(value => {
      ...value,
      quantityRule: quantityRule,
    })
  }
  let handleRarityRankRuleChange = rarityRankRule => {
    onChange(value => {
      ...value,
      rarityRankRule: rarityRankRule,
    })
  }

  <>
    <MaterialUi.Typography
      variant=#Subtitle2
      color=#TextSecondary
      classes={MaterialUi.Typography.Classes.make(~subtitle2=Cn.make(["mb-4"]), ())}>
      {React.string("alert rules (optional)")}
    </MaterialUi.Typography>
    <AlertRule_Accordion
      summaryIcon={<MaterialUi.Typography
        variant=#H5
        classes={MaterialUi.Typography.Classes.make(
          ~h5=Cn.make(["leading-none", "text-darkSecondary"]),
          (),
        )}>
        {React.string(`Ξ`)}
      </MaterialUi.Typography>}
      summaryTitle={React.string("price rule")}
      summaryDescription={React.string("filter events by price threshold")}
      initialExpanded={value->priceRule->Js.Option.isSome}
      renderDetails={(~expanded) =>
        <AlertRule_Price
          value=?{value->priceRule} onChange={handlePriceRuleChange} accordionExpanded={expanded}
        />}
    />
    <AlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<Externals_MaterialUi_Icons.StarOutline
        style={ReactDOM.Style.make(~opacity="0.42", ())}
      />}
      summaryTitle={React.string("rarity rank rule")}
      summaryDescription={React.string("filter events by asset rarity rank")}
      initialExpanded={value->rarityRankRule->Js.Option.isSome}
      renderDetails={(~expanded) =>
        <AlertRule_RarityRank
          value=?{value->rarityRankRule}
          onChange={handleRarityRankRuleChange}
          accordionExpanded={expanded}
        />}
    />
    <AlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<Externals_MaterialUi_Icons.LabelOutlined
        style={ReactDOM.Style.make(~opacity="0.42", ())}
      />}
      summaryTitle={React.string("properties rule")}
      summaryDescription={React.string("filter events by asset properties")}
      initialExpanded={value->propertiesRule->Js.Option.isSome}
      renderDetails={(~expanded) =>
        <AlertRule_Properties
          accordionExpanded={expanded}
          value=?{value->propertiesRule}
          onChange={handlePropertiesRuleChange}
          options=collectionAggregateAttributes
          isOptionsLoading={isLoadingCollectionAggregateAttributes}
          isCollectionSelected={value->collection->Js.Option.isSome}
          isOpenstore={value
          ->collection
          ->Belt.Option.map(collection =>
            collection->CollectionOption.contractAddressGet->Js.String2.toLowerCase ==
              Config.openstoreContractAddress
          )
          ->Belt.Option.getWithDefault(false)}
        />}
    />
    <AlertRule_Accordion
      className={Cn.make(["mt-8"])}
      summaryIcon={<Externals_MaterialUi_Icons.Filter1
        style={ReactDOM.Style.make(~opacity="0.42", ())}
      />}
      summaryTitle={React.string("quantity rule")}
      summaryDescription={React.string("filter events by quantity of assets")}
      initialExpanded={value->quantityRule->Js.Option.isSome}
      renderDetails={(~expanded) =>
        <AlertRule_Quantity
          value=?{value->quantityRule}
          onChange={handleQuantityRuleChange}
          accordionExpanded={expanded}
        />}
    />
  </>
}
