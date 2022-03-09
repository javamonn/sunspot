open AlertRule_Destination_Types.WebPushTemplate

@react.component
let make = (~value=?, ~onChange, ~eventType) => {
  let valueWithDefault = value->Belt.Option.getWithDefault(
    switch eventType {
    | #LISTING => defaultListingTemplate
    | #SALE => defaultSaleTemplate
    | #FLOOR_PRICE_CHANGE => defaultFloorPriceChangeTemplate
    | #SALE_VOLUME_CHANGE => defaultSaleVolumeChangeTemplate
    },
  )

  <div className={Cn.make(["flex", "flex-col"])}>
    <AlertRule_Destination_TemplateAccordion_InfoAlert eventType={eventType} />
    <MaterialUi.TextField
      label={React.string("title")}
      value={valueWithDefault->title->MaterialUi.TextField.Value.string}
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
            title: newValue,
          }),
        )
      }}
      classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mb-4"]), ())}
    />
    <MaterialUi.TextField
      label={React.string("body")}
      value={valueWithDefault->body->MaterialUi.TextField.Value.string}
      _InputProps={
        "classes": MaterialUi.Input.Classes.make(~input=Cn.make(["leading-normal"]), ()),
      }
      fullWidth={true}
      multiline={true}
      onChange={ev => {
        let target = ev->ReactEvent.Form.target
        let newValue = target["value"]
        onChange(
          Some({
            ...valueWithDefault,
            body: newValue,
          }),
        )
      }}
      classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mb-4"]), ())}
    />
    <MaterialUi.FormControl>
      <MaterialUi.InputLabel shrink=true htmlFor="">
        {React.string("image size")}
      </MaterialUi.InputLabel>
      <MaterialUi.Select
        value={MaterialUi.Select.Value.string(
          valueWithDefault->isThumbnailImageSize ? "thumbnail" : "full size",
        )}
        onChange={(ev, _) => {
          let target = ev->ReactEvent.Form.target
          let newValue = target["value"]
          onChange(
            Some({
              ...valueWithDefault,
              isThumbnailImageSize: newValue === "thumbnail",
            }),
          )
        }}>
        <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("full size")}>
          {React.string("full size")}
        </MaterialUi.MenuItem>
        <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("thumbnail")}>
          {React.string("thumbnail")}
        </MaterialUi.MenuItem>
      </MaterialUi.Select>
    </MaterialUi.FormControl>
  </div>
}
