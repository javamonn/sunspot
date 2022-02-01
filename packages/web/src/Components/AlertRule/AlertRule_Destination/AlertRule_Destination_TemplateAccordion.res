module DiscordTemplate = {
  open AlertRule_Destination.Types.DiscordTemplate

  let listingVariables = [
    ("tokenPrice", "formatted asset price in eth"),
    ("usdPrice", "formatted asset price in usd"),
    ("assetName", "asset name"),
    ("collectionName", "collection name"),
    ("sellerName", "formatted address of the the listing user"),
    ("sellerUrl", "opensea url of the listing user"),
    ("assetUrl", "opensea url of the asset"),
    ("eventCreatedDateTime", "formatted listing creation time"),
    ("collectionImageUrl", "collection image url set on opensea"),
    ("assetImageUrl", "asset image url"),
    ("satisfiedAlertRules", "formatted satisfied alert property and price rules (optional)"),
    ("quantity", "number of assets transacted (optional, null if 1)"),
  ]

  let saleVariables = [
    ("tokenPrice", "formatted asset price in eth"),
    ("usdPrice", "formatted asset price in usd"),
    ("assetName", "asset name"),
    ("collectionName", "collection name"),
    ("sellerName", "formatted eth address of the the listing user"),
    ("sellerUrl", "opensea url of the listing user"),
    ("buyerName", "formatted eth address of the buying user"),
    ("buyerUrl", "opensea url of the buying user"),
    ("assetUrl", "opensea url of the asset"),
    ("transactionHash", "formatted hash of the transaction"),
    ("transactionUrl", "etherscan url of the transaction"),
    ("eventCreatedDateTime", "formatted listing creation time"),
    ("collectionImageUrl", "collection image url set on opensea"),
    ("assetImageUrl", "asset image url"),
    ("satisfiedAlertRules", "formatted satisfied alert property and price rules (optional)"),
    ("quantity", "number of assets transacted (optional, null if 1)"),
  ]

  @react.component
  let make = (~value=?, ~onChange, ~eventType) => {
    let valueWithDefault = value->Belt.Option.getWithDefault(
      switch eventType {
      | #listing => defaultListingTemplate
      | #sale => defaultSaleTemplate
      },
    )

    let variables = switch eventType {
    | #listing => listingVariables
    | #sale => saleVariables
    }

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

    <div className={Cn.make(["flex", "flex-col"])}>
      <InfoAlert
        text="Use {variable name} to interpolate contextual values into your template."
        className={Cn.make(["mb-4"])}>
        <div className={Cn.make(["max-h-48", "overflow-y-scroll"])}>
          <MaterialUi.Table size=#Small stickyHeader={true}>
            <MaterialUi.TableHead>
              <MaterialUi.TableRow>
                <MaterialUi.TableCell
                  classes={MaterialUi.TableCell.Classes.make(
                    ~root=Cn.make(["text-darkSecondary", "font-bold"]),
                    (),
                  )}>
                  {React.string("variable name")}
                </MaterialUi.TableCell>
                <MaterialUi.TableCell
                  classes={MaterialUi.TableCell.Classes.make(
                    ~root=Cn.make(["text-darkSecondary", "font-bold"]),
                    (),
                  )}>
                  {React.string("variable description")}
                </MaterialUi.TableCell>
              </MaterialUi.TableRow>
            </MaterialUi.TableHead>
            <MaterialUi.TableBody>
              {variables->Belt.Array.map(((name, description)) =>
                <MaterialUi.TableRow key={name}>
                  <MaterialUi.TableCell
                    classes={MaterialUi.TableCell.Classes.make(
                      ~root=Cn.make(["text-darkSecondary"]),
                      (),
                    )}>
                    {React.string(name)}
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell
                    classes={MaterialUi.TableCell.Classes.make(
                      ~root=Cn.make(["text-darkSecondary"]),
                      (),
                    )}>
                    {React.string(description)}
                  </MaterialUi.TableCell>
                </MaterialUi.TableRow>
              )}
            </MaterialUi.TableBody>
          </MaterialUi.Table>
        </div>
      </InfoAlert>
      <MaterialUi.FormControl fullWidth={true}>
        <MaterialUi.TextField
          label={React.string("title")}
          value={valueWithDefault->title->MaterialUi.TextField.Value.string}
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
          label={React.string("description")}
          value={valueWithDefault
          ->description
          ->Belt.Option.getWithDefault("")
          ->MaterialUi.TextField.Value.string}
          fullWidth={true}
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
        />
        <div
          className={Cn.make([
            "flex",
            "flex-row",
            "justify-between",
            "mt-8",
            "items-center",
            "mb-2",
          ])}>
          <MaterialUi.Typography variant=#Subtitle2>
            {React.string("fields")}
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
                      <MaterialUi.IconButton
                        onClick={_ => onMoveFieldIdx(idx, idx - 1)} size=#Small>
                        <Externals.MaterialUi_Icons.KeyboardArrowUp />
                      </MaterialUi.IconButton>
                    </MaterialUi.Tooltip>
                  : React.null}
                {idx !=
                  Belt.Array.length(valueWithDefault->fields->Belt.Option.getWithDefault([])) - 1
                  ? <MaterialUi.Tooltip title={React.string("move field down")}>
                      <MaterialUi.IconButton
                        onClick={_ => onMoveFieldIdx(idx, idx + 1)} size=#Small>
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
      </MaterialUi.FormControl>
    </div>
  }
}

@react.component
let make = (~value=?, ~onChange, ~eventType: AlertRule_EventType.t, ~accordionExpanded) =>
  switch value {
  | Some(AlertRule_Destination.Types.Value.DiscordAlertDestination({template} as destination)) =>
    <DiscordTemplate
      value=?{template}
      onChange={newTemplate =>
        onChange(
          AlertRule_Destination.Types.Value.DiscordAlertDestination({
            ...destination,
            template: newTemplate,
          }),
        )}
      eventType={eventType}
    />
  | None => <InfoAlert text={"select a destination to customize alert template."} />
  | _ => <InfoAlert text={"custom templates are not yet supported for this destination."} />
  }

let make = React.memoCustomCompareProps(make, (prevProps, nextProps) =>
  !nextProps["accordionExpanded"] ||
  (nextProps["eventType"] == prevProps["eventType"] &&
    Belt.Option.eq(nextProps["value"], prevProps["value"], (a, b) => a == b))
)
