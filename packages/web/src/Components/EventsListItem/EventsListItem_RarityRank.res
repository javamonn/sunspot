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

    Js.Math.round(successCount /. (successCount +. failedCount) *. 100.0)
  | _ => 0.0
  }

  let displayIndexed = switch openSeaAsset {
  | {
      collection: Some({
        lastCollectionIndexEvent: Some({
          successfulAssetIndexEventCount,
          failedAssetIndexEventCount,
        }),
      }),
    } =>
    let success = successfulAssetIndexEventCount->Belt.Option.getWithDefault(0)
    let failed = failedAssetIndexEventCount->Belt.Option.getWithDefault(0)

    Some(`${Belt.Int.toString(success)} / ${Belt.Int.toString(success + failed)}`)
  | _ => None
  }

  let displayIndexedAt = switch openSeaAsset {
  | {collection: Some({lastCollectionIndexEvent: Some({completedAt})})} =>
    completedAt
    ->Js.Json.decodeNumber
    ->Belt.Option.map(completedAt =>
      Externals.DateFns.formatDistanceStrict(
        completedAt *. 1000.0,
        Js.Date.now(),
        Externals.DateFns.formatDistanceStrictOptions(~addSuffix=true, ()),
      )
    )
  | _ => None
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
      title={<MaterialUi.Paper
        classes={MaterialUi.Paper.Classes.make(
          ~root=Cn.make(["flex", "flex-col", "flex-1", "p-2"]),
          (),
        )}>
        <MaterialUi.ListItem
          dense={true}
          classes={MaterialUi.ListItem.Classes.make(~root=Cn.make(["bg-gray-100", "rounded"]), ())}>
          <MaterialUi.ListItemText
            primary={React.string("index status")}
            secondary={<div className={Cn.make(["flex", "flex-row", "items-center"])}>
              <span className={Cn.make(["text-darkSecondary", "text-sm", "mr-2"])}>
                {React.string(Belt.Float.toString(indexCompletionProgress) ++ "%")}
              </span>
              <MaterialUi.LinearProgress
                classes={MaterialUi.LinearProgress.Classes.make(~root=Cn.make(["flex-1"]), ())}
                variant=#Determinate
                value={MaterialUi_Types.Number.float(indexCompletionProgress)}
                color=#Primary
              />
            </div>}
          />
        </MaterialUi.ListItem>
        {displayIndexed
        ->Belt.Option.map(displayIndexed =>
          <MaterialUi.ListItem
            dense={true}
            classes={MaterialUi.ListItem.Classes.make(
              ~root=Cn.make(["bg-gray-100", "rounded", "mt-2"]),
              (),
            )}>
            <MaterialUi.ListItemText
              primary={React.string("indexed / total")} secondary={React.string(displayIndexed)}
            />
          </MaterialUi.ListItem>
        )
        ->Belt.Option.getWithDefault(React.null)}
        {displayIndexedAt
        ->Belt.Option.map(displayIndexedAt =>
          <MaterialUi.ListItem
            dense={true}
            classes={MaterialUi.ListItem.Classes.make(
              ~root=Cn.make(["bg-gray-100", "rounded", "mt-2"]),
              (),
            )}>
            <MaterialUi.ListItemText
              primary={React.string("indexed at")} secondary={React.string(displayIndexedAt)}
            />
          </MaterialUi.ListItem>
        )
        ->Belt.Option.getWithDefault(React.null)}
      </MaterialUi.Paper>}>
      <span className={Cn.make(["text-darkPrimary", "text-base", "text-base", "font-medium"])}>
        {React.string(rankText)}
      </span>
    </MaterialUi.Tooltip>
  </div>
}
