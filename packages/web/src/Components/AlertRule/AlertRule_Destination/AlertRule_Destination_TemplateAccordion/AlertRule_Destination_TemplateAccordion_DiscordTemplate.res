open AlertRule_Destination.Types.DiscordTemplate

let defaultTemplate = eventType =>
  switch eventType {
  | #LISTING => defaultListingTemplate
  | #SALE => defaultSaleTemplate
  | #FLOOR_PRICE_CHANGE => defaultFloorPriceChangeTemplate
  | #SALE_VOLUME_CHANGE => defaultSaleVolumeChangeTemplate
  }

@react.component
let make = (~value=?, ~onChange, ~eventType) => {
  let ({data: account}: Externals.Wagmi.UseAccount.result, _) = Externals.Wagmi.UseAccount.use()
  let valueWithDefault = value->Belt.Option.getWithDefault(defaultTemplate(eventType))

  let onFieldChange = (fieldIdx, newField) => {
    valueWithDefault
    ->fields
    ->Belt.Option.forEach(fields => {
      let copy = Belt.Array.copy(fields)
      let _ = Belt.Array.set(copy, fieldIdx, newField)

      onChange(
        Some({
          ...valueWithDefault,
          fields: Some(copy),
        }),
      )
    })
  }

  let onMoveFieldIdx = (sourceIdx, targetIdx) => {
    valueWithDefault
    ->fields
    ->Belt.Option.forEach(fields => {
      let newFields = Belt.Array.copy(fields)
      switch (newFields->Belt.Array.get(sourceIdx), newFields->Belt.Array.get(targetIdx)) {
      | (Some(source), Some(target)) =>
        let _ = Belt.Array.set(newFields, sourceIdx, target)
        let _ = Belt.Array.set(newFields, targetIdx, source)
        onChange(
          Some({
            ...valueWithDefault,
            fields: Some(newFields),
          }),
        )
      | _ => ()
      }
    })
  }

  let onRemoveFieldIdx = idx => {
    valueWithDefault
    ->fields
    ->Belt.Option.forEach(fields => {
      let newFields = fields->Belt.Array.copy
      let _ = Js.Array.spliceInPlace(~pos=idx, ~remove=1, ~add=[], newFields)
      onChange(
        Some({
          ...valueWithDefault,
          fields: Some(newFields),
        }),
      )
    })
  }

  let onAddField = () => {
    let newFields = valueWithDefault->fields->Belt.Option.getWithDefault([])->Belt.Array.copy
    let _ = Js.Array2.spliceInPlace(
      ~pos=0,
      ~remove=0,
      ~add=[
        {
          name: "",
          value: "",
          inline: false,
        },
      ],
      newFields,
    )
    onChange(Some({...valueWithDefault, fields: Some(newFields)}))
  }

  let onToggleDisplayProperties = () =>
    onChange(
      Some({
        ...valueWithDefault,
        displayProperties: !(valueWithDefault->displayProperties),
      }),
    )

  <div className={Cn.make(["flex", "flex-col"])}>
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
          checked={valueWithDefault->displayProperties}
          onChange={_ => onToggleDisplayProperties()}
          classes={MaterialUi.Checkbox.Classes.make(~root=Cn.make(["p-0", "mr-4"]), ())}
        />
      </div>
      <div className={Cn.make(["flex", "flex-col"])}>
        <MaterialUi.Typography variant=#Subtitle2>
          {React.string("display asset properties")}
        </MaterialUi.Typography>
        <MaterialUi.FormHelperText>
          {React.string(
            "include asset properties as alert message fields. properties are resolved in real-time on every event.",
          )}
        </MaterialUi.FormHelperText>
      </div>
    </MaterialUi.FormControl>
    <AlertRule_Destination_TemplateAccordion_InfoAlert eventType={eventType} />
    <div
      className={Cn.make(["flex", "flex-row", "justify-between", "mt-10", "items-center", "mb-4"])}>
      <MaterialUi.Typography
        variant=#Subtitle2
        classes={MaterialUi.Typography.Classes.make(~subtitle2=Cn.make(["font-bold"]), ())}>
        {React.string("alert text")}
      </MaterialUi.Typography>
    </div>
    <div className={Cn.make([])}>
      <MaterialUi.TextField
        label={React.string("message text")}
        value={valueWithDefault
        ->content
        ->Belt.Option.getWithDefault("")
        ->MaterialUi.TextField.Value.string}
        fullWidth={true}
        variant=#Filled
        onChange={ev => {
          let target = ev->ReactEvent.Form.target
          let newValue = target["value"]
          onChange(
            Some({
              ...valueWithDefault,
              content: newValue,
            }),
          )
        }}
        classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mb-4"]), ())}
        _InputProps={{
          "classes": MaterialUi.Input.Classes.make(~root=Cn.make(["bg-gray-100"]), ()),
        }}
      />
      <MaterialUi.TextField
        label={React.string("embed title")}
        value={valueWithDefault->title->MaterialUi.TextField.Value.string}
        fullWidth={true}
        variant=#Filled
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
        _InputProps={{
          "classes": MaterialUi.Input.Classes.make(~root=Cn.make(["bg-gray-100"]), ()),
        }}
      />
      <MaterialUi.TextField
        label={React.string("embed description")}
        value={valueWithDefault
        ->description
        ->Belt.Option.getWithDefault("")
        ->MaterialUi.TextField.Value.string}
        fullWidth={true}
        variant=#Filled
        onChange={ev => {
          let target = ev->ReactEvent.Form.target
          let newValue = target["value"]
          onChange(
            Some({
              ...valueWithDefault,
              description: newValue,
            }),
          )
        }}
        classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mb-4"]), ())}
        _InputProps={{
          "classes": MaterialUi.Input.Classes.make(~root=Cn.make(["bg-gray-100"]), ()),
        }}
      />
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["flex", "flex-col"]), ())}>
        <MaterialUi.InputLabel
          shrink=true
          htmlFor=""
          classes={MaterialUi.InputLabel.Classes.make(~root=Cn.make(["mt-2", "ml-3", "z-10"]), ())}>
          {React.string("embed image size")}
        </MaterialUi.InputLabel>
        <MaterialUi.Select
          variant=#Filled
          inputProps={{
            "classes": MaterialUi.Input.Classes.make(~root=Cn.make(["bg-gray-100"]), ()),
          }}
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
    <div
      className={Cn.make(["flex", "flex-row", "justify-between", "mt-10", "items-center", "mb-2"])}>
      <MaterialUi.Typography
        variant=#Subtitle2
        classes={MaterialUi.Typography.Classes.make(~subtitle2=Cn.make(["font-bold"]), ())}>
        {React.string("embed fields")}
      </MaterialUi.Typography>
      <MaterialUi.Button
        startIcon={<Externals.MaterialUi_Icons.Add />}
        size=#Small
        variant=#Outlined
        onClick={_ => onAddField()}
        classes={MaterialUi.Button.Classes.make(~label=Cn.make(["normal-case"]), ())}>
        {React.string("add field")}
      </MaterialUi.Button>
    </div>
    <MaterialUi.List classes={MaterialUi.List.Classes.make(~root=Cn.make([]), ())}>
      {valueWithDefault
      ->fields
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.mapWithIndex((idx, field) =>
        <MaterialUi.ListItem
          key={Belt.Int.toString(idx)}
          classes={MaterialUi.ListItem.Classes.make(
            ~root=Cn.make([
              "flex",
              "flex-col",
              "items-start",
              "border",
              "border-solid",
              "border-darkDivider",
              "rounded",
              "bg-gray-100",
              {idx != 0 ? "mt-4" : ""},
            ]),
            (),
          )}>
          <div
            className={Cn.make([
              "flex",
              "flex-row",
              "items-center",
              "flex-1",
              "justify-end",
              "self-stretch",
            ])}>
            {idx != 0
              ? <MaterialUi.Tooltip title={React.string("move field up")}>
                  <MaterialUi.IconButton onClick={_ => onMoveFieldIdx(idx, idx - 1)} size=#Small>
                    <Externals.MaterialUi_Icons.KeyboardArrowUp />
                  </MaterialUi.IconButton>
                </MaterialUi.Tooltip>
              : React.null}
            {idx != Belt.Array.length(valueWithDefault->fields->Belt.Option.getWithDefault([])) - 1
              ? <MaterialUi.Tooltip title={React.string("move field down")}>
                  <MaterialUi.IconButton onClick={_ => onMoveFieldIdx(idx, idx + 1)} size=#Small>
                    <Externals.MaterialUi_Icons.KeyboardArrowDown />
                  </MaterialUi.IconButton>
                </MaterialUi.Tooltip>
              : React.null}
            <MaterialUi.Tooltip title={React.string("delete field")}>
              <MaterialUi.IconButton onClick={_ => onRemoveFieldIdx(idx)} size=#Small>
                <Externals.MaterialUi_Icons.Delete />
              </MaterialUi.IconButton>
            </MaterialUi.Tooltip>
          </div>
          <MaterialUi.TextField
            fullWidth={true}
            label={React.string("name")}
            value={field->name->MaterialUi.TextField.Value.string}
            onChange={ev => {
              let target = ev->ReactEvent.Form.target
              let newValue = target["value"]
              onFieldChange(idx, {...field, name: newValue})
            }}
            classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mb-4"]), ())}
          />
          <MaterialUi.TextField
            fullWidth={true}
            label={React.string("value")}
            value={field.value->MaterialUi.TextField.Value.string}
            onChange={ev => {
              let target = ev->ReactEvent.Form.target
              let newValue = target["value"]
              onFieldChange(idx, {...field, value: newValue})
            }}
            classes={MaterialUi.TextField.Classes.make(~root=Cn.make(["mb-4"]), ())}
          />
          <MaterialUi.FormControlLabel
            label={React.string("inline")}
            control={<MaterialUi.Switch
              checked={field->inline}
              onChange={ev => {
                let target = ev->ReactEvent.Form.target
                let newValue = target["checked"]
                onFieldChange(idx, {...field, inline: newValue})
              }}
            />}
          />
        </MaterialUi.ListItem>
      )
      ->React.array}
    </MaterialUi.List>
  </div>
}
