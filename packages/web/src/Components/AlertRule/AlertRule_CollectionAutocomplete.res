open AlertModal_Types

module Query_OpenSeaCollectionsByNamePrefix = %graphql(`
  query OpenSeaCollectionsByNamePrefix($input: OpenSeaCollectionsByNamePrefixInput!) {
    collections: openSeaCollectionsByNamePrefix(input: $input) {
      items {
        name
        slug
        imageUrl
        contractAddress
      }
    }
  }
`)

module Query_OpenSeaCollectionByContractAddress = %graphql(`
  query OpenSeaCollectionByContractAddress($input: OpenSeaCollectionByContractAddressInput!) {
    collection: getOpenSeaCollectionByContractAddress(input: $input) {
      name
      slug
      imageUrl
      contractAddress
    }
  }
`)

@react.component
let make = (~value, ~onChange) => {
  let (collectionQueryInput, setCollectionQueryInput) = React.useState(_ => "")
  let (autocompleteIsOpen, setAutocompleteIsOpen) = React.useState(_ => false)
  let resultsSource = React.useRef(None)
  let (
    executeCollectionNamePrefixQuery,
    collectionNamePrefixQueryResult,
  ) = Query_OpenSeaCollectionsByNamePrefix.useLazy()
  let (
    executeContractAddressQuery,
    contractAddressQueryResult,
  ) = Query_OpenSeaCollectionByContractAddress.useLazy()

  let debouncedExecuteQuery = React.useMemo0(() => Externals.Lodash.Debounce1.make((. input) => {
      let isAddress = Js.String2.startsWith(input, "0x") && Js.String2.length(input) == 42
      if isAddress {
        resultsSource.current = Some(#ContractAddress)
        executeContractAddressQuery({input: {contractAddress: Js.String2.toLowerCase(input)}})
      } else {
        resultsSource.current = Some(#NamePrefix)
        executeCollectionNamePrefixQuery({input: {namePrefix: input}})
      }
    }, 200))

  let _ = React.useEffect1(() => {
    if Js.String2.length(collectionQueryInput) > 0 {
      debouncedExecuteQuery(. collectionQueryInput)
    }
    None
  }, [collectionQueryInput])
  let handleViewCollectionClick = (ev, url) => {
    let _ = ev->ReactEvent.Synthetic.preventDefault
    let _ = ev->ReactEvent.Synthetic.stopPropagation
    Externals.Webapi.Window.open_(url)
  }

  let (isLoadingCollectionOptions, loadingText) = switch (
    resultsSource.current,
    collectionNamePrefixQueryResult,
    contractAddressQueryResult,
  ) {
  | (None, _, _)
  | (Some(#NamePrefix), Unexecuted(_), _)
  | (Some(#ContractAddress), _, Unexecuted(_)) => (
      true,
      React.string("Filter by name or contract address..."),
    )
  | (Some(#NamePrefix), Executed({loading: true}), _)
  | (Some(#ContractAddress), _, Executed({loading: true})) => (true, React.string("Loading..."))
  | _ => (false, React.null)
  }
  let collectionOptions = switch (
    resultsSource.current,
    collectionNamePrefixQueryResult,
    contractAddressQueryResult,
  ) {
  | (None, _, _)
  | (Some(#NamePrefix), Unexecuted(_), _)
  | (Some(#NamePrefix), Executed({loading: true}), _)
  | (Some(#ContractAddress), _, Unexecuted(_))
  | (Some(#ContractAddress), _, Executed({loading: true})) => []
  | (
      Some(#NamePrefix),
      Executed({data: Some({collections: Some({items: Some(itemConnections)})})}),
      _,
    ) =>
    itemConnections->Belt.Array.keepMap(itemConnection =>
      itemConnection->Belt.Option.map(itemConnection =>
        CollectionOption.make(
          ~name=itemConnection.name,
          ~slug=itemConnection.slug,
          ~imageUrl=itemConnection.imageUrl,
          ~contractAddress=itemConnection.contractAddress,
        )
      )
    )
  | (Some(#ContractAddress), _, Executed({data: Some({collection})})) => [
      CollectionOption.make(
        ~name=collection.name,
        ~slug=collection.slug,
        ~imageUrl=collection.imageUrl,
        ~contractAddress=collection.contractAddress,
      ),
    ]
  | _ => []
  }
  let options = if Belt.Array.length(collectionOptions) > 0 {
    collectionOptions
    ->Belt.Array.map(c => MaterialUi_Types.Any(Some(c)))
    ->Belt.Array.concat([MaterialUi_Types.Any(None)])
  } else {
    []
  }

  <MaterialUi_Lab.Autocomplete
    filterOptions={MaterialUi_Types.Any(i => i)}
    classes={MaterialUi_Lab.Autocomplete.Classes.make(~paper=Cn.make(["bg-gray-100"]), ())}
    _open={autocompleteIsOpen}
    value={MaterialUi_Types.Any(Js.Null.fromOption(value))}
    onChange={(_, collection, _) => {
      switch collection->Obj.magic->Js.Nullable.toOption {
      | Some(collectionOption) => onChange(Some(collectionOption))
      | _ => ()
      }
    }}
    onInputChange={(_, value, _) => {
      setCollectionQueryInput(_ => value)
    }}
    getOptionLabel={opt =>
      switch opt {
      | Some(opt) => opt->CollectionOption.nameGet->Belt.Option.getWithDefault("Unnamed Collection")
      | None => ""
      }}
    onOpen={_ => setAutocompleteIsOpen(_ => true)}
    onClose={(_, _) => setAutocompleteIsOpen(_ => false)}
    loading={isLoadingCollectionOptions}
    getOptionSelected={(opt1, opt2) =>
      switch (opt1, opt2) {
      | (Some(opt1), Some(opt2)) =>
        Obj.magic(CollectionOption.slugGet(opt1) == CollectionOption.slugGet(opt2))
      | _ => Obj.magic(false)
      }}
    options={options}
    loadingText={loadingText}
    renderInput={params =>
      React.cloneElement(
        <MaterialUi.TextField label={React.string("collection")} variant=#Outlined />,
        params,
      )}
    renderOption={(opt, _) =>
      switch opt {
      | Some(collectionOption) =>
        <div className={Cn.make(["flex", "flex-row", "justify-center", "items-center", "flex-1"])}>
          <CollectionListItem
            imageUrl={CollectionOption.imageUrlGet(collectionOption)}
            primary={collectionOption
            ->CollectionOption.nameGet
            ->Belt.Option.getWithDefault("Unnamed Collection")}
            secondary={collectionOption->CollectionOption.slugGet->React.string}
            bare={true}
          />
          <a
            className={Cn.make(["flex", "items-center", "justify-center", "opacity-50"])}
            href={`https://opensea.io/collection/${collectionOption->CollectionOption.slugGet}`}
            target="_blank"
            rel="noopener noreferrer"
            onClick={ev =>
              handleViewCollectionClick(
                ev,
                `https://opensea.io/collection/${collectionOption->CollectionOption.slugGet}`,
              )}>
            <Externals_MaterialUi_Icons.OpenInNew />
          </a>
        </div>
      | None =>
        <div className={Cn.make(["cursor-default", "pointer-events-none"])}>
          <MaterialUi.ListItemText
            classes={MaterialUi.ListItemText.Classes.make(
              ~primary=Cn.make(["text-darkDisabled", "text-sm", "text-center", "p-2"]),
              (),
            )}
            primary={React.string(
              "can't find the collection that you're looking for? try searching by contract address.",
            )}
          />
        </div>
      }}
  />
}
