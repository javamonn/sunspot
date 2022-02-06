let listingVariables = [
  ("tokenPrice", "formatted asset price in eth"),
  ("usdPrice", "formatted asset price in usd"),
  ("assetName", "asset name"),
  ("collectionName", "collection name"),
  ("sellerName", "formatted address of the the listing user"),
  ("sellerUrl", "opensea url of the listing user"),
  ("assetUrl", "opensea url of the asset"),
  ("eventCreatedDateTime", "formatted listing creation time"),
  ("collectionImageUrl", "collection image url set on opensea"),
  ("assetImageUrl", "asset image url"),
  ("satisfiedAlertRules", "formatted satisfied alert property and price rules (optional)"),
  ("quantity", "number of assets transacted (optional, null if 1)"),
]

let saleVariables = [
  ("tokenPrice", "formatted asset price in eth"),
  ("usdPrice", "formatted asset price in usd"),
  ("assetName", "asset name"),
  ("collectionName", "collection name"),
  ("sellerName", "formatted eth address of the the listing user"),
  ("sellerUrl", "opensea url of the listing user"),
  ("buyerName", "formatted eth address of the buying user"),
  ("buyerUrl", "opensea url of the buying user"),
  ("assetUrl", "opensea url of the asset"),
  ("transactionHash", "formatted hash of the transaction"),
  ("transactionUrl", "etherscan url of the transaction"),
  ("eventCreatedDateTime", "formatted listing creation time"),
  ("collectionImageUrl", "collection image url set on opensea"),
  ("assetImageUrl", "asset image url"),
  ("satisfiedAlertRules", "formatted satisfied alert property and price rules (optional)"),
  ("quantity", "number of assets transacted (optional, null if 1)"),
]

@react.component
let make = (~eventType) => {
  let variables = switch eventType {
  | #listing => listingVariables
  | #sale => saleVariables
  }

  <InfoAlert
    text="Use {variable name} to interpolate contextual values into your template."
    className={Cn.make(["mb-4"])}>
    <div className={Cn.make(["max-h-48", "overflow-y-scroll"])}>
      <MaterialUi.Table size=#Small stickyHeader={true}>
        <MaterialUi.TableHead>
          <MaterialUi.TableRow>
            <MaterialUi.TableCell
              classes={MaterialUi.TableCell.Classes.make(
                ~root=Cn.make(["text-darkSecondary", "font-bold"]),
                (),
              )}>
              {React.string("variable name")}
            </MaterialUi.TableCell>
            <MaterialUi.TableCell
              classes={MaterialUi.TableCell.Classes.make(
                ~root=Cn.make(["text-darkSecondary", "font-bold"]),
                (),
              )}>
              {React.string("variable description")}
            </MaterialUi.TableCell>
          </MaterialUi.TableRow>
        </MaterialUi.TableHead>
        <MaterialUi.TableBody>
          {variables->Belt.Array.map(((name, description)) =>
            <MaterialUi.TableRow key={name}>
              <MaterialUi.TableCell
                classes={MaterialUi.TableCell.Classes.make(
                  ~root=Cn.make(["text-darkSecondary"]),
                  (),
                )}>
                {React.string(name)}
              </MaterialUi.TableCell>
              <MaterialUi.TableCell
                classes={MaterialUi.TableCell.Classes.make(
                  ~root=Cn.make(["text-darkSecondary"]),
                  (),
                )}>
                {React.string(description)}
              </MaterialUi.TableCell>
            </MaterialUi.TableRow>
          )}
        </MaterialUi.TableBody>
      </MaterialUi.Table>
    </div>
  </InfoAlert>
}
