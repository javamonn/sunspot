module Fragment_CollectionIndexSummary_CollectionIndexEvent = %graphql(`
  fragment CollectionIndexSummary_CollectionIndexEvent on CollectionIndexEvent {
    completionReason
    successfulAssetIndexEventCount
    failedAssetIndexEventCount
    completedAt
  }
`)

@react.component
let make = (
  ~collectionIndexEvent: option<Fragment_CollectionIndexSummary_CollectionIndexEvent.t>,
) => {
  let (indexCompletionProgress, displayIndexed, displayIndexedAt) =
    collectionIndexEvent
    ->Belt.Option.map(({
      completionReason,
      successfulAssetIndexEventCount,
      failedAssetIndexEventCount,
      completedAt,
    }) => {
      let indexCompletionProgress = switch (completionReason, successfulAssetIndexEventCount) {
      | (Some(#EXECUTED), Some(successfulAssetIndexEventCount))
        if successfulAssetIndexEventCount > 0 =>
        let successCount = Belt.Float.fromInt(successfulAssetIndexEventCount)
        let failedCount =
          failedAssetIndexEventCount->Belt.Option.getWithDefault(0)->Belt.Float.fromInt

        Js.Math.round(successCount /. (successCount +. failedCount) *. 100.0)
      | _ => 0.0
      }

      let displayIndexed = {
        let success = successfulAssetIndexEventCount->Belt.Option.getWithDefault(0)
        let failed = failedAssetIndexEventCount->Belt.Option.getWithDefault(0)

        Some(`${Belt.Int.toString(success)} / ${Belt.Int.toString(success + failed)}`)
      }

      let displayIndexedAt =
        completedAt
        ->Js.Json.decodeNumber
        ->Belt.Option.map(completedAt =>
          Externals.DateFns.formatDistanceStrict(
            completedAt *. 1000.0,
            Js.Date.now(),
            Externals.DateFns.formatDistanceStrictOptions(~addSuffix=true, ()),
          )
        )

      (indexCompletionProgress, displayIndexed, displayIndexedAt)
    })
    ->Belt.Option.getWithDefault((0.0, None, None))

  <MaterialUi.Paper
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
  </MaterialUi.Paper>
}
