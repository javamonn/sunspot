include AlertsTable_Types
open AlertsTable_Types

// static widths to support ssr rehydration
let loadingWidths = [
  (0, 139, 131, 140, 160, 130),
  (1, 217, 147, 140, 120, 130),
  (2, 147, 141, 117, 0, 200),
  (3, 190, 109, 113, 140, 100),
  (4, 187, 154, 102, 130, 80),
  (5, 126, 96, 108, 100, 140),
  (6, 192, 127, 118, 0, 160),
]

@react.component
let make = (~rows, ~onRowClick, ~isLoading) =>
  <MaterialUi.TableContainer
    classes={MaterialUi.TableContainer.Classes.make(~root={Cn.make(["mt-4", "flex-1"])}, ())}>
    <MaterialUi.Table stickyHeader={true}>
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
          ? loadingWidths->Belt.Array.map(((idx, width1, width2, width3, width4, width5)) =>
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
                    height={MaterialUi_Lab.Skeleton.Height.int(28)}
                    width={MaterialUi_Lab.Skeleton.Width.int(width4)}
                  />
                </MaterialUi.TableCell>
                <MaterialUi.TableCell>
                  <MaterialUi_Lab.Skeleton
                    variant=#Text
                    height={MaterialUi_Lab.Skeleton.Height.int(48)}
                    width={MaterialUi_Lab.Skeleton.Width.int(width5)}
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
                    <div className={Cn.make(["flex", "flex-row", "items-center"])}>
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
                  <MaterialUi.TableCell> {React.string(row.eventType)} </MaterialUi.TableCell>
                  <MaterialUi.TableCell>
                    {row.rules
                    ->Belt.Array.getBy(rule =>
                      switch rule {
                      | PriceRule(_) => true
                      | _ => false
                      }
                    )
                    ->Belt.Option.flatMap(rule =>
                      switch rule {
                      | PriceRule({modifier, price}) =>
                        Some(
                          <MaterialUi.Typography color=#TextPrimary variant=#Body2>
                            {React.string("price ")}
                            {React.string(modifier)}
                            {React.string(` Ξ`)}
                            {React.string(price)}
                          </MaterialUi.Typography>,
                        )
                      | _ => None
                      }
                    )
                    ->Belt.Option.getWithDefault(React.null)}
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell>
                    <AlertsTable_PropertiesCell row={row} />
                  </MaterialUi.TableCell>
                  <MaterialUi.TableCell>
                    <AlertsTable_DestinationCell row={row} />
                  </MaterialUi.TableCell>
                </MaterialUi.TableRow>,
                {"onClick": _ => onRowClick(row)},
              )
            )}
      </MaterialUi.TableBody>
    </MaterialUi.Table>
    {!isLoading && Belt.Array.length(rows) == 0
      ? <div className={Cn.make(["flex", "flex-col"])}>
          <MaterialUi.Typography
            variant=#Subtitle1
            color=#TextSecondary
            classes={MaterialUi.Typography.Classes.make(
              ~subtitle1=Cn.make(["text-center", "mt-12", "whitespace-pre"]),
              (),
            )}>
            {React.string("to get started, create an alert.")}
          </MaterialUi.Typography>
        </div>
      : React.null}
  </MaterialUi.TableContainer>
