open AlertRule_Destination_Types.WebPushTemplate

@react.component
let make = (~value=?, ~onChange, ~eventType) => {
  let ({data: account}: Externals.Wagmi.UseAccount.result, _) = Externals.Wagmi.UseAccount.use()
  let valueWithDefault = value->Belt.Option.getWithDefault(
    switch eventType {
    | #LISTING => defaultListingTemplate
    | #SALE => defaultSaleTemplate
    | #FLOOR_PRICE_CHANGE => defaultFloorPriceChangeTemplate
    | #SALE_VOLUME_CHANGE => defaultSaleVolumeChangeTemplate
    },
  )

  let onToggleQuickbuy = () =>
    onChange(
      Some({
        ...valueWithDefault,
        quickbuy: !(valueWithDefault->quickbuy),
      }),
    )

  <div className={Cn.make(["flex", "flex-col"])}>
    {switch eventType {
    | #LISTING =>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(
          ~root=Cn.make([
            "flex",
            "mb-6",
            "flex-row",
            "border",
            "border-darkDivider",
            "rounded",
            "border-solid",
            "p-4",
          ]),
          (),
        )}>
        <div className={Cn.make(["flex", "items-center", "justify-center"])}>
          <MaterialUi.Checkbox
            color=#Primary
            checked={valueWithDefault->quickbuy}
            onChange={_ => onToggleQuickbuy()}
            classes={MaterialUi.Checkbox.Classes.make(~root=Cn.make(["p-0", "mr-4"]), ())}
          />
        </div>
        <div className={Cn.make(["flex", "flex-col"])}>
          <MaterialUi.Typography variant=#Subtitle2>
            {React.string("quick-buy")}
          </MaterialUi.Typography>
          <MaterialUi.FormHelperText>
            {React.string(
              "prompt asset quick-buy when alert is triggered. quick-buys interact with the OpenSea exchange contract, but are routed directly through sunspot for increased execution speed.",
            )}
          </MaterialUi.FormHelperText>
        </div>
      </MaterialUi.FormControl>
    | _ => React.null
    }}
    <AlertRule_Destination_TemplateAccordion_InfoAlert
      eventType={eventType} className={Cn.make(["mb-4"])}
    />
    <MaterialUi.TextField
      label={React.string("title")}
      value={valueWithDefault->title->MaterialUi.TextField.Value.string}
      variant=#Filled
      _InputProps={
        "classes": MaterialUi.Input.Classes.make(
          ~input=Cn.make(["leading-normal", "bg-gray-100"]),
          (),
        ),
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
      variant=#Filled
      _InputProps={
        "classes": MaterialUi.Input.Classes.make(
          ~input=Cn.make(["leading-normal"]),
          ~multiline=Cn.make(["bg-gray-100"]),
          (),
        ),
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
      <MaterialUi.InputLabel
        shrink=true
        htmlFor=""
        classes={MaterialUi.InputLabel.Classes.make(~root=Cn.make(["mt-2", "ml-3", "z-10"]), ())}>
        {React.string("image size")}
      </MaterialUi.InputLabel>
      <MaterialUi.Select
        variant=#Filled
        value={MaterialUi.Select.Value.string(
          valueWithDefault->isThumbnailImageSize ? "thumbnail" : "full size",
        )}
        inputProps={{
          "classes": MaterialUi.Input.Classes.make(~root=Cn.make(["bg-gray-100"]), ()),
        }}
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
