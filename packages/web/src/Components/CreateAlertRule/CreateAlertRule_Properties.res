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
  let make = (~value, ~onRemoveValueAttribute) =>
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
      ])}
      style={ReactDOM.Style.make(~minHeight="4.5rem", ())}>
      {value->Belt.Option.getWithDefault([])->Belt.Array.length == 0
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
      {value
      ->Belt.Option.getWithDefault([])
      ->Belt.Array.mapWithIndex((idx, attribute) => {
        let (traitType, displayValue) = switch attribute.value {
        | StringValue({value}) => (attribute.traitType, value)
        | NumberValue({value}) => (attribute.traitType, Belt.Float.toString(value))
        }

        <li
          key={`${traitType}-${displayValue}`}
          className={Cn.make([
            "flex",
            "flex-col",
            "items-start",
            "mb-3",
            CnRe.on(
              Cn.make(["mr-3"]),
              value->Belt.Option.getWithDefault([])->Belt.Array.length - 1 != idx,
            ),
          ])}>
          <MaterialUi.Typography color=#TextSecondary variant=#Caption>
            {React.string(traitType)}
          </MaterialUi.Typography>
          <MaterialUi.Chip
            label={React.string(displayValue)}
            onDelete={_ => onRemoveValueAttribute(idx)}
            clickable={true}
            color=#Primary
            variant=#Default
            size=#Small
          />
        </li>
      })
      ->React.array}
    </ul>
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
                      onClick={_ =>
                        switch valueIdx {
                        | Some(idx) => onRemoveValueAttribute(idx)
                        | None =>
                          onAddValueAttribute({
                            Value.traitType: aggreggateAttribute->Option.traitType,
                            value: attributeValue,
                          })
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

@react.component
let make = (~value=?, ~options, ~isOptionsLoading, ~onChange) => {
  let handleRemoveValueAttribute = idx =>
    value->Belt.Option.forEach(value => {
      let copy = Belt.Array.copy(value)
      let _ = Js.Array2.spliceInPlace(copy, ~pos=idx, ~remove=1, ~add=[])
      onChange(Belt.Array.length(copy) == 0 ? None : Some(copy))
    })
  let handleAddValueAttribute = attribute =>
    value->Belt.Option.getWithDefault([])->Belt.Array.concat([attribute])->Js.Option.some->onChange

  <div className={Cn.make(["flex", "flex-col", "flex-1"])}>
    <Value value onRemoveValueAttribute={handleRemoveValueAttribute} />
    {isOptionsLoading
      ? <OptionsLoading />
      : <Options
          value
          options
          onRemoveValueAttribute={handleRemoveValueAttribute}
          onAddValueAttribute={handleAddValueAttribute}
        />}
  </div>
}
