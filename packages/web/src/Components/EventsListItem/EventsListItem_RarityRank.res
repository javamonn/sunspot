module Fragment_EventsListItem_RarityRank_OpenSeaAsset = %graphql(`
  fragment EventsListItem_RarityRank_OpenSeaAsset on OpenSeaAsset {
    id
    rarityRank
    collection {
      lastCollectionIndexEvent {
        completionReason
        successfulAssetIndexEventCount
        failedAssetIndexEventCount
        completedAt
      }
    }
  }
`)

@react.component
let make = (~openSeaAsset: Fragment_EventsListItem_RarityRank_OpenSeaAsset.t) => {
  let rankText = switch openSeaAsset {
  | {
      rarityRank: Some(rarityRank),
      collection: Some({lastCollectionIndexEvent: Some({completionReason: Some(#EXECUTED)})}),
    } =>
    `#${Belt.Int.toString(rarityRank)}`
  | _ => "N/A"
  }
  let indexCompletionProgress = switch openSeaAsset {
  | {
      collection: Some({
        lastCollectionIndexEvent: Some({
          completionReason: Some(#EXECUTED),
          successfulAssetIndexEventCount: Some(successfulAssetIndexEventCount),
          failedAssetIndexEventCount,
        }),
      }),
    } if successfulAssetIndexEventCount > 0 =>
    let successCount = Belt.Float.fromInt(successfulAssetIndexEventCount)
    let failedCount = failedAssetIndexEventCount->Belt.Option.getWithDefault(0)->Belt.Float.fromInt

    successCount /. (successCount +. failedCount)
  | _ => 0.0
  }

  <div className={Cn.make(["flex", "flex-row", "flex-1"])}>
    <div className={Cn.make(["w-40", "flex-shrink-0", "pt-3"])}>
      <Externals.MaterialUi_Icons.LabelOutlined
        style={ReactDOM.Style.make(~opacity="0.42", ~height="16px", ())}
      />
      <span className={Cn.make(["text-darkSecondary", "text-sm"])}> {React.string("rank")} </span>
    </div>
    <span className={Cn.make(["text-darkPrimary", "text-sm"])}> {React.string(rankText)} </span>
    <MaterialUi.CircularProgress
      size={MaterialUi.CircularProgress.Size.int(18)}
      variant=#Determinate
      value={MaterialUi_Types.Number.float(indexCompletionProgress)}
    />
  </div>
}
