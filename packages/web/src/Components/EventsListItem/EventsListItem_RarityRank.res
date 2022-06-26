module CollectionIndexSummary_CollectionIndexEvent = CollectionIndexSummary.Fragment_CollectionIndexSummary_CollectionIndexEvent

module Fragment_EventsListItem_RarityRank_OpenSeaAsset = %graphql(`
  fragment EventsListItem_RarityRank_OpenSeaAsset on OpenSeaAsset {
    id
    rarityRank
    collection {
      lastCollectionIndexEvent {
        ...CollectionIndexSummary_CollectionIndexEvent
      }
    }
  }
`)

@react.component
let make = (~openSeaAsset: Fragment_EventsListItem_RarityRank_OpenSeaAsset.t) => {
  let rankText = switch openSeaAsset {
  | {
      rarityRank: Some(rarityRank),
      collection: Some({
        lastCollectionIndexEvent: Some({
          completionReason: Some(#EXECUTED),
          successfulAssetIndexEventCount: Some(s),
          failedAssetIndexEventCount: Some(f),
        }),
      }),
    } if Belt.Float.fromInt(s) /. (Belt.Float.fromInt(s) +. Belt.Float.fromInt(f)) >= 0.90 =>
    `#${Belt.Int.toString(rarityRank)}`
  | _ => "n/a"
  }

  <div className={Cn.make(["flex", "flex-row", "flex-1", "items-center", "flex-shrink-0"])}>
    <div className={Cn.make(["w-32", "flex-shrink-0", "pr-4", "text-right"])}>
      <Externals.MaterialUi_Icons.StarOutline
        style={ReactDOM.Style.make(~opacity="0.42", ~height="18px", ())}
      />
      <span className={Cn.make(["text-darkSecondary", "text-sm"])}> {React.string("rank")} </span>
    </div>
    <MaterialUi.Tooltip
      classes={MaterialUi.Tooltip.Classes.make(~tooltip=Cn.make(["bg-white", "w-60", "p-0"]), ())}
      title={<div>
        <CollectionIndexSummary
          collectionIndexEvent={openSeaAsset.collection->Belt.Option.flatMap(c =>
            c.lastCollectionIndexEvent
          )}
        />
      </div>}>
      <span className={Cn.make(["text-darkPrimary", "text-base", "text-base", "font-medium"])}>
        {React.string(rankText)}
      </span>
    </MaterialUi.Tooltip>
  </div>
}
