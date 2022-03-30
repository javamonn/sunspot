let listingVariables = [
  ("tokenPrice", "formatted asset price in eth"),
  ("usdPrice", "formatted asset price in usd"),
  ("assetName", "asset name"),
  ("assetTokenId", "asset token id"),
  ("collectionName", "collection name"),
  ("sellerName", "formatted address of the the listing user"),
  ("sellerUrl", "opensea url of the listing user"),
  ("assetUrl", "opensea url of the asset"),
  ("eventCreatedDateTime", "formatted listing creation time"),
  ("collectionFloorTokenPrice", "formatted collection floor price in eth"),
  ("collectionFloorUsdPrice", "formatted collection floor price in usd"),
  ("collectionImageUrl", "collection image url set on opensea"),
  ("assetImageUrl", "asset image url"),
  ("satisfiedAlertRules", "formatted satisfied alert property and price rules (optional)"),
  ("quantity", "number of assets transacted (optional, null if 1)"),
]

let saleVariables = [
  ("tokenPrice", "formatted asset price in eth"),
  ("usdPrice", "formatted asset price in usd"),
  ("assetName", "asset name"),
  ("assetTokenId", "asset token id"),
  ("collectionName", "collection name"),
  ("sellerName", "formatted eth address of the the listing user"),
  ("sellerUrl", "opensea url of the listing user"),
  ("buyerName", "formatted eth address of the buying user"),
  ("buyerUrl", "opensea url of the buying user"),
  ("assetUrl", "opensea url of the asset"),
  ("transactionHash", "formatted hash of the transaction"),
  ("transactionUrl", "etherscan url of the transaction"),
  ("eventCreatedDateTime", "formatted listing creation time"),
  ("collectionFloorTokenPrice", "formatted collection floor price in eth"),
  ("collectionFloorUsdPrice", "formatted collection floor price in usd"),
  ("collectionImageUrl", "opensea collection image url"),
  ("assetImageUrl", "asset image url"),
  ("satisfiedAlertRules", "formatted satisfied alert property and price rules (optional)"),
  ("quantity", "number of assets transacted (optional, null if 1)"),
]

let floorPriceChangeVariables = [
  ("changeValue", "formatted change value"),
  ("timeElapsed", "formatted change time window"),
  ("changeVerb", "one of (\"increase\", \"decrease\") describing change direction"),
  ("collectionName", "collection name"),
  ("collectionUrl", "opensea collection image url"),
  ("changeIndicatorArrow", "one of (\"↗\", \"↘\") indicating change direction"),
  ("eventCreatedDateTime", "formatted event creation time"),
  ("eventsScatterPlotImageUrl", "image url of most recent 1h events scatterplot"),
  ("target15mSaleCount", "count of sale events to occur in the last 15m"),
  ("target15mSaleChange", "formatted change of 15m sale events relative to previous 15m"),
  ("target15mListingCount", "count of listing events to occur in the last 15m"),
  ("target15mListingChange", "formatted change of 15m listing events relative to previous 15m"),
  ("collectionImageUrl", "opensea collecti  n image url"),
  ("floorPrice", "floor price of collection derived from previous 15 events"),
]

let saleVolumeChangeVariables = [
  ("timeElapsed", "formatted change time window"),
  ("targetCount", "count of sale events within the most recent time interval"),
  ("targetBucket", "formatted time interval used to bucket sale events"),
  ("changeValue", "formatted change value"),
  ("changeVerb", "one of (\"increase\", \"decrease\") describing change direction"),
  ("collectionName", "collection name"),
  ("collectionUrl", "opensea collection image url"),
  ("collectionImageUrl", "opensea collection image url"),
  ("changeIndicatorArrow", "one of (\"↗\", \"↘\") indicating change direction"),
  ("eventCreatedDateTime", "formatted event creation time"),
  ("eventsScatterPlotImageUrl", "url of most recent 1h events scatterplot image"),
  ("floorPrice", "floor price of collection derived from previous 15 events"),
]

@react.component
let make = (~eventType, ~className=?) => {
  let variables = switch eventType {
  | #LISTING => listingVariables
  | #SALE => saleVariables
  | #FLOOR_PRICE_CHANGE => floorPriceChangeVariables
  | #SALE_VOLUME_CHANGE => saleVolumeChangeVariables
  }

  <InfoAlert
    text={React.string("Use {variable name} to interpolate contextual values into your template.")}
    ?className>
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
