type trait =
  | StringTrait({name: string, value: string})
  | NumberTrait({name: string, value: float})

type priceFilter =
  | Max(float)
  | Min(float)

let makeAssetsUrl = (~collectionSlug, ~traitsFilter=?, ~priceFilter=?, ~eventType, ()) => {
  let stringTraitQuery =
    traitsFilter
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.reduce(Belt.Map.String.empty, (memo, trait) =>
      switch trait {
      | StringTrait({name}) =>
        let existingValue = memo->Belt.Map.String.get(name)->Belt.Option.getWithDefault([])
        Belt.Map.String.set(memo, name, Belt.Array.concat(existingValue, [trait]))
      | NumberTrait({name}) => memo
      }
    )
    ->Belt.Map.String.valuesToArray
    ->Belt.Array.mapWithIndex((macroIdx, traits) => {
      traits->Belt.Array.mapWithIndex((traitIdx, trait) =>
        switch trait {
        | StringTrait({name, value}) =>
          let valueQuery = `search[stringTraits][${Belt.Int.toString(
              macroIdx,
            )}][values][${Belt.Int.toString(traitIdx)}]=${Js.Global.encodeURIComponent(value)}`
          let nameQuery = `search[stringTraits][${Belt.Int.toString(
              macroIdx,
            )}][name]=${Js.Global.encodeURIComponent(name)}`
          if traitIdx == 0 {
            `${nameQuery}&${valueQuery}`
          } else {
            valueQuery
          }
        | NumberTrait(_) => ""
        }
      )
    })
    ->Belt.Array.concatMany
    ->Belt.Array.keep(q => Js.String2.length(q) > 0)
    ->Belt.Array.joinWith("&", i => i)

  let numberTraitQuery =
    traitsFilter
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.reduce(Belt.Map.String.empty, (memo, trait) =>
      switch trait {
      | NumberTrait({name, value}) => {
          let newValue = switch Belt.Map.String.get(memo, name) {
          | Some((min, max)) =>
            if value < min {
              (value, max)
            } else if value > max {
              (min, value)
            } else {
              (min, max)
            }
          | None => (value, value)
          }
          Belt.Map.String.set(memo, name, newValue)
        }
      | StringTrait(_) => memo
      }
    )
    ->Belt.Map.String.toArray
    ->Belt.Array.mapWithIndex((idx, (name, (minValue, maxValue))) => {
      let nameQuery = `search[numericTraits][${Belt.Int.toString(
          idx,
        )}][name]=${Js.Global.encodeURIComponent(name)}`
      let minValueQuery = `search[numericTraits][${Belt.Int.toString(
          idx,
        )}][ranges][0][min]=${minValue->Belt.Float.toString->Js.Global.encodeURIComponent}`
      let maxValueQuery = `search[numericTraits][${Belt.Int.toString(
          idx,
        )}][ranges][0][max]=${maxValue->Belt.Float.toString->Js.Global.encodeURIComponent}`

      `${nameQuery}&${minValueQuery}&${maxValueQuery}`
    })
    ->Belt.Array.joinWith("&", i => i)

  let priceQuery = switch priceFilter {
  | Some(Max(n)) =>
    `search[priceFilter][symbol]=ETH&search[priceFilter][max]=${Belt.Float.toString(n)}`
  | Some(Min(n)) =>
    `search[priceFilter][symbol]=ETH&search[priceFilter][min]=${Belt.Float.toString(n)}`
  | None => ""
  }

  let sortQuery = switch eventType {
  | #LISTING => "search[sortAscending]=false&search[sortBy]=LISTING_DATE"
  | #SALE => "search[sortAscending]=false&search[sortBy]=LAST_SALE_DATE"
  | _ => ""
  }

  let query =
    [sortQuery, stringTraitQuery, numberTraitQuery, priceQuery]
    ->Belt.Array.keep(q => Js.String2.length(q) > 0)
    ->Belt.Array.joinWith("&", i => i)

  `https://opensea.io/assets/${collectionSlug}?${query}`
}

