module CollectionIndexSummary_CollectionIndexEvent = CollectionIndexSummary.Fragment_CollectionIndexSummary_CollectionIndexEvent

module Fragment_OrderSection_RarityRank_OpenSeaAsset = %graphql(`
  fragment OrderSection_RarityRank_OpenSeaAsset on OpenSeaAsset {
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
let make = (~openSeaAsset: Fragment_OrderSection_RarityRank_OpenSeaAsset.t) => {
  let rankText = switch openSeaAsset {
  | {
      rarityRank: Some(rarityRank),
      collection: Some({lastCollectionIndexEvent: Some({completionReason: Some(#EXECUTED)})}),
    } =>
    `#${Belt.Int.toString(rarityRank)}`
  | _ => "n/a"
  }

  <>
    <h1 className={Cn.make(["text-darkSecondary", "font-mono", "mb-2", "text-sm"])}>
      <Externals.MaterialUi_Icons.StarOutline
        style={ReactDOM.Style.make(~opacity="0.50", ~height="18px", ())}
      />
      {React.string("rank")}
    </h1>
    <div className={Cn.make(["mb-8", "flex"])}>
      <MaterialUi.Tooltip
        classes={MaterialUi.Tooltip.Classes.make(~tooltip=Cn.make(["bg-white", "w-60", "p-0"]), ())}
        title={<div>
          <CollectionIndexSummary
            collectionIndexEvent={openSeaAsset.collection->Belt.Option.flatMap(c =>
              c.lastCollectionIndexEvent
            )}
          />
        </div>}>
        <h2
          className={Cn.make([
            "text-darkPrimary",
            "text-base",
            "font-bold",
            "text-xl",
            "font-mono",
          ])}>
          {React.string(rankText)}
        </h2>
      </MaterialUi.Tooltip>
    </div>
  </>
}
