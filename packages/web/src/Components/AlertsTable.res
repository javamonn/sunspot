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
type row = {
  id: string,
  collectionName: option<string>,
  collectionSlug: string,
  collectionImageUrl: option<string>,
  event: string,
  rule: option<priceRule>,
}

@react.component
let make = (~rows) =>
  <MaterialUi.TableContainer
    classes={MaterialUi.TableContainer.Classes.make(~root={Cn.make(["mt-6"])}, ())}>
    <MaterialUi.Table>
      <MaterialUi.TableHead>
        <MaterialUi.TableRow>
          {columns
          ->Belt.Array.map(column =>
            <MaterialUi.TableCell id={column.label} align={#Left}>
              {React.string(column.label)}
            </MaterialUi.TableCell>
          )
          ->React.array}
        </MaterialUi.TableRow>
      </MaterialUi.TableHead>
      <MaterialUi.TableBody>
        {rows->Belt.Array.map(row =>
          <MaterialUi.TableRow key={row.id} hover={true}>
            <MaterialUi.TableCell>
              <CollectionListItem
                primary={row.collectionName->Belt.Option.getWithDefault("Unnamed Collection")}
                secondary={row.collectionSlug}
                imageUrl={row.collectionImageUrl}
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
          </MaterialUi.TableRow>
        )}
      </MaterialUi.TableBody>
    </MaterialUi.Table>
  </MaterialUi.TableContainer>
