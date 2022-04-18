let eventsScatterplotHours = 4.0

@react.component
let make = (
  ~collection: OrderSection_GraphQL.Fragment_OrderSection_OpenSeaOrder.OrderSection_OpenSeaAsset.t_collection,
) => {
  let (isLightboxOpen, setIsLightboxOpen) = React.useState(_ => false)
  let eventsScatterplotSrc = {
    let endCreatedAtMinuteTime =
      Js.Math.floor_float(Js.Math.floor_float(Js.Date.now() /. 1000.0) /. 60.0) *. 60.0
    let startCreatedAtMinuteTime = endCreatedAtMinuteTime -. 60.0 *. 60.0 *. eventsScatterplotHours

    let start = startCreatedAtMinuteTime->Belt.Float.toInt->Belt.Int.toString
    let end = endCreatedAtMinuteTime->Belt.Float.toInt->Belt.Int.toString
    let collectionSlug = collection.slug

    `https://dpldouen3w8e7.cloudfront.net/production/events-scatterplot?collectionSlug=${collectionSlug}&startCreatedAtMinuteTime=${start}&endCreatedAtMinuteTime=${end}`
  }

  <>
    <img
      onClick={_ => {
        setIsLightboxOpen(_ => true)
      }}
      src={eventsScatterplotSrc}
      className={Cn.make([
        "flex-1",
        "border",
        "border-solid",
        "rounded",
        "cursor-pointer",
        "border-darkBorder",
        "mt-8",
      ])}
    />
    {isLightboxOpen
      ? <Externals.ReactImageLightbox
          mainSrc={eventsScatterplotSrc}
          onCloseRequest={() => setIsLightboxOpen(_ => false)}
          imagePadding={30}
          reactModalStyle={{
            "overlay": {
              "zIndex": "1500",
            },
          }}
        />
      : React.null}
  </>
}
