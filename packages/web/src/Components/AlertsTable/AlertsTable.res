let styles = %raw("require('./AlertsTable.module.css')")

include AlertsTable_Types
open AlertsTable_Types

// static widths to support ssr rehydration
let loadingWidths = [
  (0, 139, 131, 140, 130),
  (1, 217, 147, 140, 130),
  (2, 147, 141, 117, 200),
  (3, 190, 109, 113, 100),
  (4, 187, 154, 102, 80),
  (5, 126, 96, 108, 140),
  (6, 192, 127, 118, 160),
]

@react.component
let make = (~rows, ~onRowClick, ~onCreateAlertClick, ~isLoading) => <>
  <MaterialUi.TableContainer
    classes={MaterialUi.TableContainer.Classes.make(
      ~root={Cn.make(["mt-4", "flex-1", "sm:mt-0"])},
      (),
    )}>
    <MaterialUi.Table stickyHeader={true}>
      <MaterialUi.TableHead>
        <MaterialUi.TableRow>
          {columns
          ->Belt.Array.map(column =>
            <MaterialUi.TableCell
              key={column.label}
              align={#Left}
              classes={MaterialUi.TableCell.Classes.make(~root=Cn.make(["bg-white"]), ())}>
              {React.string(column.label)}
            </MaterialUi.TableCell>
          )
          ->React.array}
        </MaterialUi.TableRow>
      </MaterialUi.TableHead>
      <MaterialUi.TableBody>
        {isLoading
          ? loadingWidths->Belt.Array.map(((idx, width1, width2, width3, width4)) =>
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
                <MaterialUi.TableCell>
                  <MaterialUi_Lab.Skeleton
                    variant=#Text
                    height={MaterialUi_Lab.Skeleton.Height.int(48)}
                    width={MaterialUi_Lab.Skeleton.Width.int(width4)}
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
                  <MaterialUi.TableCell
                    classes={MaterialUi.TableCell.Classes.make(
                      ~root=Cn.make(["sm:py-2", "sm:px-2"]),
                      (),
                    )}>
                    <div className={Cn.make(["flex", "flex-row", "items-center", "sm:w-64"])}>
                      <CollectionListItem
                        primary={row.collectionName->Belt.Option.getWithDefault(
                          "Unnamed Collection",
                        )}
                        secondary={<a
                          href={row.externalUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          style={ReactDOM.Style.make(
                            ~textDecorationStyle="dotted",
                            ~textDecorationLine="underline",
                            (),
                          )}>
                          {React.string(row.collectionSlug)}
                        </a>}
                        imageUrl={row.collectionImageUrl}
                        disableGutters={true}
                        listItemClasses={MaterialUi.ListItem.Classes.make(
                          ~root=Cn.make(["p-0", "w-auto"]),
                          (),
                        )}
                      />
                      {row.disabledInfo
                      ->Belt.Option.map(copy =>
                        <MaterialUi.Tooltip title={React.string(copy)}>
                          <Externals.MaterialUi_Icons.Error
                            className={Cn.make(["w-5", "h-5", "ml-2", "text-red-400"])}
                          />
                        </MaterialUi.Tooltip>
                      )
                      ->Belt.Option.getWithDefault(React.null)}
                    </div>
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell
                    classes={MaterialUi.TableCell.Classes.make(
                      ~root=Cn.make(["sm:py-2", "sm:px-2"]),
                      (),
                    )}>
                    {React.string(row.eventType)}
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell
                    classes={MaterialUi.TableCell.Classes.make(
                      ~root=Cn.make(["sm:py-2", "sm:px-2"]),
                      (),
                    )}>
                    <AlertsTable_RulesCell rules={row.rules} />
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell
                    classes={MaterialUi.TableCell.Classes.make(
                      ~root=Cn.make(["sm:py-2", "sm:px-2"]),
                      (),
                    )}>
                    <AlertsTable_DestinationCell row={row} />
                  </MaterialUi.TableCell>
                </MaterialUi.TableRow>,
                {"onClick": _ => onRowClick(row)},
              )
            )}
      </MaterialUi.TableBody>
    </MaterialUi.Table>
    {!isLoading && Belt.Array.length(rows) == 0
      ? <div
          className={Cn.make([
            "flex",
            "flex-col",
            "justify-center",
            "items-center",
            "mt-12",
            "sm:mt-0",
            styles["emptyPlaceholder"],
          ])}>
          <MaterialUi.Button
            onClick={_ => onCreateAlertClick()}
            variant=#Outlined
            classes={MaterialUi.Button.Classes.make(
              ~label=Cn.make(["lowercase", "py-2", "px-2", "text-darkSecondary"]),
              (),
            )}>
            {React.string("create an alert to get started.")}
          </MaterialUi.Button>
          <h2 className={Cn.make(["text-sm", "mt-8", "text-darkSecondary"])}>
            {React.string(
              "alerts notify you when listing, sales, floor price, or sales volume change events occur.",
            )}
          </h2>
        </div>
      : React.null}
    <AlertsFooter className={Cn.make(["hidden", "sm:block", "sm:border-t-0"])} />
  </MaterialUi.TableContainer>
</>
