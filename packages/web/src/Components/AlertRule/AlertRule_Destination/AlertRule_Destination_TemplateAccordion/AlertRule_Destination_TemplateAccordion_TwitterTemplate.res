open AlertRule_Destination_Types.TwitterTemplate

@react.component
let make = (~value=?, ~onChange, ~eventType) => {
  let valueWithDefault = value->Belt.Option.getWithDefault(
    switch eventType {
    | #LISTING => defaultListingTemplate
    | #SALE => defaultSaleTemplate
    | #FLOOR_PRICE_CHANGE => defaultFloorPriceChangeTemplate
    | #SALE_VOLUME_CHANGE => defaultSaleVolumeChangeTemplate
    | #FLOOR_PRICE_THRESHOLD => defaultFloorPriceThresholdTemplate
    },
  )

  <div className={Cn.make(["flex", "flex-col"])}>
    <AlertRule_Destination_TemplateAccordion_InfoAlert
      eventType={eventType} className={Cn.make(["mb-4"])}
    />
    <MaterialUi.TextField
      label={React.string("text")}
      value={valueWithDefault->text->MaterialUi.TextField.Value.string}
      _InputProps={
        "classes": MaterialUi.Input.Classes.make(~input=Cn.make(["leading-normal"]), ()),
      }
      multiline={true}
      fullWidth={true}
      onChange={ev => {
        let target = ev->ReactEvent.Form.target
        let newValue = target["value"]
        onChange(
          Some({
            ...valueWithDefault,
            text: newValue,
          }),
        )
      }}
    />
    <MaterialUi.TextField
      label={React.string("image url")}
      value={valueWithDefault
      ->imageUrl
      ->Belt.Option.getWithDefault("")
      ->MaterialUi.TextField.Value.string}
      classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mt-4"]), ())}
      _InputProps={
        "classes": MaterialUi.Input.Classes.make(~input=Cn.make(["leading-normal"]), ()),
      }
      fullWidth={true}
      onChange={ev => {
        let target = ev->ReactEvent.Form.target
        let newValue = target["value"]
        onChange(
          Some({
            ...valueWithDefault,
            imageUrl: Js.String2.length(newValue) > 0 ? Some(newValue) : None,
          }),
        )
      }}
    />
  </div>
}
