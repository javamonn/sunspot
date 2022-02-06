type attributeValue =
  | StringValue({value: string})
  | NumberValue({value: float})

module Option = {
  @deriving(accessors)
  type t = {
    traitType: string,
    count: float,
    values: array<attributeValue>,
  }
}

module Value = {
  @deriving(accessors)
  type item = {
    traitType: string,
    value: attributeValue,
  }

  @deriving(accessors)
  type t = array<item>

  @react.component
  let make = (~value, ~onRemoveValueAttribute) => {
    let valuesByTraitType =
      value
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.reduce(Belt.Map.String.empty, (memo, value) =>
        Belt.Map.String.set(
          memo,
          value->traitType,
          Belt.Array.concat(Belt.Map.String.getWithDefault(memo, value->traitType, []), [value]),
        )
      )

    <ul
      className={Cn.make([
        "flex",
        "flex-1",
        "bg-gray-100",
        "border-solid",
        "border-b",
        "border-darkDisabled",
        "flex-wrap",
        "px-4",
        "py-2",
        "mb-6",
        "rounded-t-md",
        "overflow-x-auto",
      ])}
      style={ReactDOM.Style.make(~minHeight="4.5rem", ())}>
      {valuesByTraitType->Belt.Map.String.size == 0
        ? <MaterialUi.Typography
            color=#TextSecondary
            variant=#Body1
            classes={MaterialUi.Typography.Classes.make(
              ~body1=Cn.make(["leading-none", "self-center"]),
              (),
            )}>
            {React.string("filtered properties")}
          </MaterialUi.Typography>
        : React.null}
      {valuesByTraitType
      ->Belt.Map.String.toArray
      ->Belt.Array.mapWithIndex((idx, (traitType, values)) => {
        <div className={Cn.make(["flex", "flex-row"])}>
          {idx !== 0
            ? <div
                style={ReactDOM.Style.make(~height="24px", ())}
                className={Cn.make([
                  "font-mono",
                  "text-darkSecondary",
                  "italic",
                  "text-xs",
                  "px-2",
                  "flex",
                  "items-center",
                  "self-end",
                  "mb-3",
                ])}>
                {React.string("and")}
              </div>
            : React.null}
          <li key={traitType} className={Cn.make(["flex", "flex-col", "items-start", "mb-3"])}>
            <MaterialUi.Typography color=#TextSecondary variant=#Caption>
              {React.string(traitType)}
            </MaterialUi.Typography>
            <div className={Cn.make(["flex", "flex-row"])}>
              {values
              ->Belt.Array.mapWithIndex((idx, value) => {
                let displayValue = switch value.value {
                | StringValue({value}) => value
                | NumberValue({value}) => Belt.Float.toString(value)
                }
                <>
                  <MaterialUi.Chip
                    classes={MaterialUi.Chip.Classes.make(
                      ~root=Cn.make(
                        if idx === 0 && Belt.Array.length(values) > 1 {
                          ["rounded-r-none"]
                        } else if (
                          idx === Belt.Array.length(values) - 1 && Belt.Array.length(values) > 1
                        ) {
                          ["rounded-l-none"]
                        } else if Belt.Array.length(values) > 1 {
                          ["rounded-r-none", "rounded-l-none"]
                        } else {
                          []
                        },
                      ),
                      (),
                    )}
                    label={React.string(displayValue)}
                    onDelete={_ => onRemoveValueAttribute(value)}
                    clickable={true}
                    color=#Primary
                    variant=#Default
                    size=#Small
                  />
                  {idx !== Belt.Array.length(values) - 1
                    ? <div
                        className={Cn.make([
                          "bg-themePrimary",
                          "text-lightSecondary",
                          "font-mono",
                          "text-xs",
                          "italic",
                          "px-2",
                          "flex",
                          "items-center",
                        ])}>
                        {React.string("or")}
                      </div>
                    : React.null}
                </>
              })
              ->React.array}
            </div>
          </li>
        </div>
      })
      ->React.array}
    </ul>
  }
}

module Options = {
  @react.component
  let make = (~options, ~value, ~onRemoveValueAttribute, ~onAddValueAttribute) =>
    <ul className={Cn.make(["flex", "flex-col", "flex-1"])}>
      {options
      ->Belt.Array.map(aggreggateAttribute => {
        <li key={aggreggateAttribute->Option.traitType}>
          <MaterialUi.Accordion variant=#Outlined square={true}>
            <MaterialUi.AccordionSummary expandIcon={<Externals.MaterialUi_Icons.ExpandMore />}>
              <MaterialUi.Typography variant=#Body1 color=#Primary>
                {aggreggateAttribute->Option.traitType->React.string}
              </MaterialUi.Typography>
            </MaterialUi.AccordionSummary>
            <MaterialUi.AccordionDetails>
              <ul className={Cn.make(["flex", "flex-1", "flex-wrap"])}>
                {aggreggateAttribute
                ->Option.values
                ->Belt.Array.mapWithIndex((idx, attributeValue) => {
                  let displayValue = switch attributeValue {
                  | StringValue({value}) => value
                  | NumberValue({value}) => Belt.Float.toString(value)
                  }
                  let valueIdx =
                    value
                    ->Belt.Option.getWithDefault([])
                    ->Belt.Array.getIndexBy(valueItem => {
                      let valueEq = switch (Value.value(valueItem), attributeValue) {
                      | (StringValue({value: valueA}), StringValue({value: valueB})) =>
                        valueA == valueB
                      | (NumberValue({value: valueA}), NumberValue({value: valueB})) =>
                        valueA == valueB
                      | _ => false
                      }
                      let traitTypeEq =
                        Option.traitType(aggreggateAttribute) == Value.traitType(valueItem)
                      valueEq && traitTypeEq
                    })

                  <li
                    key={displayValue}
                    className={CnRe.on(
                      Cn.make(["mr-3", "mb-3"]),
                      Belt.Array.length(aggreggateAttribute->Option.values) - 1 != idx,
                    )}>
                    <MaterialUi.Chip
                      variant={valueIdx->Js.Option.isSome ? #Default : #Outlined}
                      color=#Primary
                      label={React.string(displayValue)}
                      clickable={true}
                      onClick={_ => {
                        let value = {
                          Value.traitType: aggreggateAttribute->Option.traitType,
                          value: attributeValue,
                        }
                        switch valueIdx {
                        | Some(_) => onRemoveValueAttribute(value)
                        | None => onAddValueAttribute(value)
                        }
                      }}
                    />
                  </li>
                })
                ->React.array}
              </ul>
            </MaterialUi.AccordionDetails>
          </MaterialUi.Accordion>
        </li>
      })
      ->React.array}
    </ul>
}

module OptionsLoading = {
  @react.component
  let make = () => {
    let widths = React.useRef(Belt.Array.makeBy(5, i => Js.Math.random_int(1, 100) + 100))

    <ul className={Cn.make(["flex", "flex-col", "flex-1"])}>
      {widths.current
      ->Belt.Array.mapWithIndex((idx, width) =>
        <MaterialUi.Accordion
          variant=#Outlined square={true} expanded={false} key={Belt.Int.toString(idx)}>
          <MaterialUi.AccordionSummary expandIcon={<Externals.MaterialUi_Icons.ExpandMore />}>
            <MaterialUi_Lab.Skeleton
              variant=#Text
              height={MaterialUi_Lab.Skeleton.Height.int(28)}
              width={MaterialUi_Lab.Skeleton.Width.int(width)}
            />
          </MaterialUi.AccordionSummary>
        </MaterialUi.Accordion>
      )
      ->React.array}
    </ul>
  }
}

module OptionsEmpty = {
  @react.component
  let make = (~isOpenstore, ~isCollectionSelected) => {
    let copy = if !isCollectionSelected {
      "select a collection to filter events by asset properties."
    } else if isOpenstore {
      "collections utilizing the opensea shared storefront contract do not currently support property filters."
    } else {
      "properties for this collection are not indexed. if this seems incorrect, reach out to us for support."
    }

    <InfoAlert text={copy} />
  }
}

@react.component
let make = (
  ~value=?,
  ~options,
  ~isOptionsLoading,
  ~isOpenstore,
  ~isCollectionSelected,
  ~onChange,
  ~accordionExpanded,
) => {
  let handleRemoveValueAttribute = valueToRemove =>
    value->Belt.Option.forEach(value => {
      value
      ->Belt.Array.getIndexBy(prospect => {
        let traitTypeEq = prospect->Value.traitType === valueToRemove->Value.traitType
        switch (prospect->Value.value, valueToRemove->Value.value) {
        | (StringValue({value: valueA}), StringValue({value: valueB})) if traitTypeEq =>
          valueA === valueB
        | (NumberValue({value: valueA}), NumberValue({value: valueB})) if traitTypeEq =>
          valueA === valueB
        | _ => false
        }
      })
      ->Belt.Option.forEach(idx => {
        let copy = Belt.Array.copy(value)
        let _ = Js.Array2.spliceInPlace(copy, ~pos=idx, ~remove=1, ~add=[])
        onChange(Belt.Array.length(copy) == 0 ? None : Some(copy))
      })
    })
  let handleAddValueAttribute = attribute =>
    value->Belt.Option.getWithDefault([])->Belt.Array.concat([attribute])->Js.Option.some->onChange

  <div className={Cn.make(["flex", "flex-col", "flex-1", "overflow-x-hidden"])}>
    {isOptionsLoading
      ? <>
          <Value value onRemoveValueAttribute={handleRemoveValueAttribute} /> <OptionsLoading />
        </>
      : Belt.Array.length(options) > 0
      ? <>
        <Value value onRemoveValueAttribute={handleRemoveValueAttribute} />
        <Options
          value
          options
          onRemoveValueAttribute={handleRemoveValueAttribute}
          onAddValueAttribute={handleAddValueAttribute}
        />
      </>
      : <OptionsEmpty isCollectionSelected={isCollectionSelected} isOpenstore={isOpenstore} />}
  </div>
}

let make = React.memoCustomCompareProps(make, (prevProps, nextProps) =>
  !nextProps["accordionExpanded"] ||
  (nextProps["isOptionsLoading"] == prevProps["isOptionsLoading"] &&
  nextProps["isOpenstore"] == prevProps["isOpenstore"] &&
  nextProps["isCollectionSelected"] == prevProps["isCollectionSelected"] &&
  nextProps["options"] == prevProps["options"] &&
  Belt.Option.eq(nextProps["value"], prevProps["value"], (a, b) => a == b))
)
