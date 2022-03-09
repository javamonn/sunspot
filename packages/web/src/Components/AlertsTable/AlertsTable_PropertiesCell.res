open AlertsTable_Types

@react.component
let make = (~row) => {
  let propertyRules = row.rules->Belt.Array.keepMap(rule =>
    switch rule {
    | PropertyRule({traitType, displayValue}) =>
      Some({traitType: traitType, displayValue: displayValue})
    | PriceRule(_) | QuantityRule(_) | RelativeChangeRule(_) => None
    }
  )
  let displayValuesByTraitType =
    propertyRules
    ->Belt.Array.slice(~offset=0, ~len=2)
    ->Belt.Array.reduce(Belt.Map.String.empty, (memo, {traitType, displayValue}) =>
      Belt.Map.String.set(
        memo,
        traitType,
        Belt.Array.concat(Belt.Map.String.getWithDefault(memo, traitType, []), [displayValue]),
      )
    )

  <ul className={Cn.make(["flex", "flex-row", "items-end"])}>
    {displayValuesByTraitType
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
            ->Belt.Array.mapWithIndex((idx, displayValue) => {
              <>
                <MaterialUi.Chip
                  classes={MaterialUi.Chip.Classes.make(
                    ~root=Cn.make(
                      if idx === 0 && Belt.Array.length(values) > 1 {
                        ["rounded-r-none", "border-r-0"]
                      } else if (
                        idx === Belt.Array.length(values) - 1 && Belt.Array.length(values) > 1
                      ) {
                        ["rounded-l-none", "border-l-0"]
                      } else if Belt.Array.length(values) > 1 {
                        ["rounded-r-none", "rounded-l-none", "border-r-0", "border-l-0"]
                      } else {
                        []
                      },
                    ),
                    (),
                  )}
                  label={<span style={ReactDOM.Style.make(~marginTop="3px", ~display="block", ())}>
                    {React.string(displayValue)}
                  </span>}
                  clickable={true}
                  color=#Primary
                  variant=#Outlined
                  size=#Small
                />
                {idx !== Belt.Array.length(values) - 1
                  ? <div
                      style={ReactDOM.Style.make(~borderColor="#000", ())}
                      className={Cn.make([
                        "text-darkSecondary",
                        "font-mono",
                        "text-xs",
                        "italic",
                        "px-1",
                        "flex",
                        "items-center",
                        "border-t",
                        "border-b",
                        "border-solid",
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
    {propertyRules->Belt.Array.length > 2
      ? <MaterialUi.Chip
          classes={MaterialUi.Chip.Classes.make(~root=Cn.make(["mb-3", "ml-2"]), ())}
          label={React.string(`+ ${Belt.Int.toString(Belt.Array.length(row.rules) - 2)}`)}
          color=#Primary
          variant=#Outlined
          size=#Small
          clickable={true}
        />
      : React.null}
  </ul>
}
