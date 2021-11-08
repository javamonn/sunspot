type column = {
  label: string,
  minWidth: int,
}

let columns = [
  {
    label: "collection",
    minWidth: 300,
  },
  {
    label: "event",
    minWidth: 120,
  },
  {
    label: "rule",
    minWidth: 120,
  },
]

type priceRule = {modifier: string, price: string}
@deriving(accessors)
type row = {
  id: string,
  collectionName: option<string>,
  collectionSlug: string,
  collectionImageUrl: option<string>,
  event: string,
  rule: option<priceRule>,
}


// static widths to support ssr rehydration
let loadingWidths = [
  (0, 139, 131, 140),
  (1, 217, 147, 140),
  (2, 147, 141, 117),
  (3, 190, 109, 113),
  (4, 187, 154, 102),
  (5, 126, 96, 108),
  (6, 192, 127, 118),
]

@react.component
let make = (~rows, ~onRowClick, ~isUnsupportedBrowser, ~isLoading) => <>
  <MaterialUi.TableContainer
    classes={MaterialUi.TableContainer.Classes.make(~root={Cn.make(["mt-6"])}, ())}>
    <MaterialUi.Table>
      <MaterialUi.TableHead>
        <MaterialUi.TableRow>
          {columns
          ->Belt.Array.map(column =>
            <MaterialUi.TableCell key={column.label} align={#Left}>
              {React.string(column.label)}
            </MaterialUi.TableCell>
          )
          ->React.array}
        </MaterialUi.TableRow>
      </MaterialUi.TableHead>
      <MaterialUi.TableBody>
        {isLoading
          ? loadingWidths->Belt.Array.map(((idx, width1, width2, width3)) =>
              <MaterialUi.TableRow key={Belt.Int.toString(idx)}>
                <MaterialUi.TableCell
                  classes={MaterialUi.TableCell.Classes.make(
                    ~root=Cn.make(["flex", "flex-row", "items-center"]),
                    (),
                  )}>
                  <MaterialUi_Lab.Skeleton
                    classes={MaterialUi_Lab.Skeleton.Classes.make(~root=Cn.make(["mr-4"]), ())}
                    variant=#Circle
                    height={MaterialUi_Lab.Skeleton.Height.int(38)}
                    width={MaterialUi_Lab.Skeleton.Width.int(38)}
                  />
                  <MaterialUi_Lab.Skeleton
                    variant=#Text
                    height={MaterialUi_Lab.Skeleton.Height.int(56)}
                    width={MaterialUi_Lab.Skeleton.Width.int(width1)}
                  />
                </MaterialUi.TableCell>
                <MaterialUi.TableCell>
                  <MaterialUi_Lab.Skeleton
                    variant=#Text
                    height={MaterialUi_Lab.Skeleton.Height.int(28)}
                    width={MaterialUi_Lab.Skeleton.Width.int(width2)}
                  />
                </MaterialUi.TableCell>
                <MaterialUi.TableCell>
                  <MaterialUi_Lab.Skeleton
                    variant=#Text
                    height={MaterialUi_Lab.Skeleton.Height.int(28)}
                    width={MaterialUi_Lab.Skeleton.Width.int(width3)}
                  />
                </MaterialUi.TableCell>
              </MaterialUi.TableRow>
            )
          : rows->Belt.Array.map(row =>
              React.cloneElement(
                <MaterialUi.TableRow
                  key={row.id}
                  hover={true}
                  classes={MaterialUi.TableRow.Classes.make(
                    ~hover=Cn.make(["cursor-pointer"]),
                    (),
                  )}>
                  <MaterialUi.TableCell>
                    <CollectionListItem
                      primary={row.collectionName->Belt.Option.getWithDefault("Unnamed Collection")}
                      secondary={row.collectionSlug}
                      imageUrl={row.collectionImageUrl}
                      disableGutters={true}
                      listItemClasses={MaterialUi.ListItem.Classes.make(~root=Cn.make(["p-0"]), ())}
                    />
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell> {React.string(row.event)} </MaterialUi.TableCell>
                  <MaterialUi.TableCell>
                    {row.rule
                    ->Belt.Option.map(rule => <>
                      {React.string("price ")}
                      {React.string(rule.modifier)}
                      {React.string(" ")}
                      {React.string(rule.price)}
                    </>)
                    ->Belt.Option.getWithDefault(React.null)}
                  </MaterialUi.TableCell>
                </MaterialUi.TableRow>,
                {"onClick": _ => onRowClick(row)},
              )
            )}
      </MaterialUi.TableBody>
    </MaterialUi.Table>
  </MaterialUi.TableContainer>
  {!isLoading && (Belt.Array.length(rows) == 0 || isUnsupportedBrowser)
    ? <MaterialUi.Typography
        variant=#Subtitle1
        color=#TextSecondary
        classes={MaterialUi.Typography.Classes.make(
          ~subtitle1=Cn.make(["text-center", "mt-12", "whitespace-pre"]),
          (),
        )}>
        {isUnsupportedBrowser
          ? React.string(
              "sunspot uses the web push api, which is not supported by your browser. \n\nto get started, switch to a browser with web push support, such as chrome or firefox.",
            )
          : React.string("to get started, connect your wallet and create an alert.")}
      </MaterialUi.Typography>
    : React.null}
</>
