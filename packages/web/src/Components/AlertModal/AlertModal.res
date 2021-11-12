let styles = %raw("require('./AlertModal.module.css')")

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

module Query_OpenSeaCollectionAggregateAttributes = %graphql(`
  query OpenSeaCollectionAggregateAttributes($input: OpenSeaCollectionByContractAddressInput!) {
    collection: getOpenSeaCollectionByContractAddress(input: $input) {
      attributes {
        traitType
        count
        values {
          ... on OpenSeaCollectionAttributeNumberValue {
            numberValue: value
          }
          ... on OpenSeaCollectionAttributeStringValue {
            stringValue: value
          }
        }
      }
    }
  }
`)

module CollectionOption = {
  @deriving(abstract)
  type t = {
    name: option<string>,
    slug: string,
    imageUrl: option<string>,
    contractAddress: string,
  }
  let make = t
  external unsafeFromJs: Js.t<'a> => t = "%identity"
}

module Value = {
  @deriving(accessors)
  type t = {
    id: string,
    collection: option<CollectionOption.t>,
    priceRule: option<CreateAlertRule_Price.t>,
    propertiesRule: option<CreateAlertRule_Properties.Value.t>,
  }

  let make = (~id, ~collection, ~priceRule, ~propertiesRule) => {
    id: id,
    collection: collection,
    priceRule: priceRule,
    propertiesRule: propertiesRule,
  }

  let empty = () => {
    id: Externals.UUID.make(),
    collection: None,
    priceRule: None,
    propertiesRule: None,
  }
}

let validate = value => {
  let collectionValid = value->Value.collection->Js.Option.isSome
  let priceRuleValid =
    value
    ->Value.priceRule
    ->Belt.Option.flatMap(priceRule =>
      priceRule
      ->CreateAlertRule_Price.value
      ->Belt.Option.flatMap(Belt.Float.fromString)
      ->Belt.Option.map(value => value >= 0.0)
    )
    ->Belt.Option.getWithDefault(false)

  if !collectionValid {
    Some("collection is required.")
  } else if !priceRuleValid {
    Some("price rule value must be a positive number.")
  } else {
    None
  }
}

@react.component
let make = (
  ~isOpen,
  ~onClose,
  ~onExited=?,
  ~value,
  ~onChange,
  ~isActioning,
  ~onAction,
  ~actionLabel,
  ~title,
  ~renderOverflowActionMenuItems=?,
) => {
  let (autocompleteIsOpen, setAutocompleteIsOpen) = React.useState(_ => false)
  let (collectionQueryInput, setCollectionQueryInput) = React.useState(_ => "")
  let (
    executeCollectionNamePrefixQuery,
    collectionNamePrefixQueryResult,
  ) = Query_OpenSeaCollectionsByNamePrefix.useLazy()
  let (
    executeContractAddressQuery,
    contractAddressQueryResult,
  ) = Query_OpenSeaCollectionByContractAddress.useLazy()
  let (
    executeCollectionAggregateAttributesQuery,
    collectionAggregateAttributesResult,
  ) = Query_OpenSeaCollectionAggregateAttributes.useLazy()
  let resultsSource = React.useRef(None)

  let debouncedExecuteQuery = React.useMemo0(() => Externals.Lodash.Debounce1.make((. input) => {
      let isAddress = Js.String2.startsWith(input, "0x") && Js.String2.length(input) == 42
      if isAddress {
        resultsSource.current = Some(#ContractAddress)
        executeContractAddressQuery({input: {contractAddress: input}})
      } else {
        resultsSource.current = Some(#NamePrefix)
        executeCollectionNamePrefixQuery({input: {namePrefix: input}})
      }
    }, 200))
  let (validationError, setValidationError) = React.useState(_ => None)

  let _ = React.useEffect1(() => {
    if Js.String2.length(collectionQueryInput) > 0 {
      debouncedExecuteQuery(. collectionQueryInput)
    }
    None
  }, [collectionQueryInput])
  let _ = React.useEffect1(() => {
    value
    ->Value.collection
    ->Belt.Option.forEach(collection => {
      executeCollectionAggregateAttributesQuery({
        input: {contractAddress: collection->CollectionOption.contractAddressGet},
      })
    })
    None
  }, [value->Value.collection])

  let handlePriceRuleChange = priceRule =>
    onChange({
      ...value,
      Value.priceRule: Some(priceRule),
    })
  let handlePropertiesRuleChange = propertiesRule =>
    onChange({
      ...value,
      Value.propertiesRule: Some(propertiesRule),
    })
  let handleExited = () => {
    setCollectionQueryInput(_ => "")
    setValidationError(_ => None)
    onExited->Belt.Option.forEach(fn => fn())
  }
  let handleAction = () => {
    let validationResult = validate(value)
    setValidationError(_ => validationResult)
    switch validationResult {
    | None => onAction()
    | Some(_) => ()
    }
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

  let (
    isLoadingCollectionAggregateAttributes,
    collectionAggregateAttributes,
  ) = switch collectionAggregateAttributesResult {
  | Executed({data: Some({collection: {attributes}})}) =>
    let collectionAggregateAttributes = attributes->Belt.Array.map(aggreggateAttribute => {
      CreateAlertRule_Properties.Option.traitType: aggreggateAttribute.traitType,
      count: aggreggateAttribute.count,
      values: aggreggateAttribute.values->Belt.Array.keepMap(value =>
        switch value {
        | #OpenSeaCollectionAttributeNumberValue({numberValue}) =>
          Some(CreateAlertRule_Properties.NumberValue({value: numberValue}))
        | #OpenSeaCollectionAttributeStringValue({stringValue}) =>
          Some(CreateAlertRule_Properties.StringValue({value: stringValue}))
        | #FutureAddedValue(_) => None
        }
      ),
    })
    (false, collectionAggregateAttributes)
  | Executed({loading: true}) => (true, [])
  | _ => (false, [])
  }

  <MaterialUi.Dialog
    _open={isOpen}
    onClose={(_, _) => onClose()}
    onExited={_ => handleExited()}
    classes={MaterialUi.Dialog.Classes.make(~paper=styles["dialogPaper"], ())}>
    <MaterialUi.DialogTitle
      disableTypography=true
      classes={MaterialUi.DialogTitle.Classes.make(
        ~root=Cn.make(["flex", "justify-between", "items-center"]),
        (),
      )}>
      <MaterialUi.Typography
        color=#Primary
        variant=#H6
        classes={MaterialUi.Typography.Classes.make(~root=Cn.make(["leading-none"]), ())}>
        {React.string(title)}
      </MaterialUi.Typography>
      {renderOverflowActionMenuItems
      ->Belt.Option.map(renderOverflowActionMenuItems =>
        <IconMenu
          icon={<Externals.MaterialUi_Icons.MoreVert />}
          renderItems={renderOverflowActionMenuItems}
          anchorOrigin={
            open MaterialUi.Menu
            AnchorOrigin.make(
              ~horizontal=Horizontal.enum(Horizontal_enum.left),
              ~vertical=Vertical.enum(Vertical_enum.bottom),
              (),
            )
          }
          menuClasses={MaterialUi.Menu.Classes.make(~paper=Cn.make(["bg-gray-100"]), ())}
        />
      )
      ->Belt.Option.getWithDefault(React.null)}
    </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["flex", "flex-col"]), ())}>
      {validationError
      ->Belt.Option.map(error =>
        <MaterialUi_Lab.Alert
          severity=#Error classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
          {React.string(error)}
        </MaterialUi_Lab.Alert>
      )
      ->Belt.Option.getWithDefault(React.null)}
      <MaterialUi_Lab.Autocomplete
        filterOptions={MaterialUi_Types.Any(i => i)}
        classes={MaterialUi_Lab.Autocomplete.Classes.make(~paper=Cn.make(["bg-gray-100"]), ())}
        _open={autocompleteIsOpen}
        value={MaterialUi_Types.Any(Js.Null.fromOption(value.collection))}
        onChange={(_, collection, _) => {
          onChange({
            ...value,
            collection: collection->Obj.magic,
          })
        }}
        onInputChange={(_, value, _) => {
          setCollectionQueryInput(_ => value)
        }}
        getOptionLabel={opt =>
          opt->CollectionOption.nameGet->Belt.Option.getWithDefault("Unnamed Collection")}
        onOpen={_ => setAutocompleteIsOpen(_ => true)}
        onClose={(_, _) => setAutocompleteIsOpen(_ => false)}
        loading={isLoadingCollectionOptions}
        getOptionSelected={(opt1, opt2) =>
          Obj.magic(CollectionOption.slugGet(opt1) == CollectionOption.slugGet(opt2))}
        options={collectionOptions->Belt.Array.map(c => MaterialUi_Types.Any(c))}
        loadingText={loadingText}
        renderInput={params =>
          React.cloneElement(
            <MaterialUi.TextField label={React.string("collection")} variant=#Outlined />,
            params,
          )}
        renderOption={(opt, _) =>
          <CollectionListItem
            imageUrl={CollectionOption.imageUrlGet(opt)}
            primary={opt
            ->CollectionOption.nameGet
            ->Belt.Option.getWithDefault("Unnamed Collection")}
            secondary={CollectionOption.slugGet(opt)}
            bare={true}
          />}
      />
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-8", "w-1/3", "pr-4"]), ())}>
        <MaterialUi.InputLabel shrink=true id="CreateAlertModal_action" htmlFor="">
          {React.string("event")}
        </MaterialUi.InputLabel>
        <MaterialUi.Tooltip
          title={React.string(
            "Only list events are currently supported, but more are coming soon.",
          )}>
          <MaterialUi.Select
            labelId="CreateAlertModal_action"
            value={MaterialUi.Select.Value.string("list")}
            disabled=true
            fullWidth=true>
            <MaterialUi.MenuItem value={MaterialUi.MenuItem.Value.string("list")}>
              {React.string("list")}
            </MaterialUi.MenuItem>
          </MaterialUi.Select>
        </MaterialUi.Tooltip>
      </MaterialUi.FormControl>
      <CreateAlertRule_Accordion
        className={Cn.make(["mt-8"])}
        summaryIcon={<MaterialUi.Typography
          variant=#H5
          color=#Secondary
          classes={MaterialUi.Typography.Classes.make(~h5=Cn.make(["leading-none"]), ())}>
          {React.string(`Ξ`)}
        </MaterialUi.Typography>}
        summaryTitle={React.string("price rule")}
        summaryDescription={React.string("filter events by price threshold")}
        details={<CreateAlertRule_Price
          value=?{value->Value.priceRule} onChange={handlePriceRuleChange}
        />}
      />
      <CreateAlertRule_Accordion
        className={Cn.make(["mt-8"])}
        summaryIcon={<Externals_MaterialUi_Icons.LabelOutlined
          style={ReactDOM.Style.make(~opacity="0.42", ())}
        />}
        summaryTitle={React.string("properties rule")}
        summaryDescription={React.string("filter events by asset properties")}
        details={<CreateAlertRule_Properties
          value=?{value->Value.propertiesRule}
          onChange={handlePropertiesRuleChange}
          options=collectionAggregateAttributes
          isOptionsLoading={isLoadingCollectionAggregateAttributes}
        />}
      />
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions
      classes={MaterialUi.DialogActions.Classes.make(~root=Cn.make(["mt-8"]), ())}>
      <MaterialUi.Button
        variant=#Text
        color=#Primary
        disabled={isActioning}
        onClick={_ => onClose()}
        classes={MaterialUi.Button.Classes.make(
          ~root=Cn.make(["mr-2"]),
          ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
          (),
        )}>
        {React.string("cancel")}
      </MaterialUi.Button>
      <MaterialUi.Button
        variant=#Contained
        color=#Primary
        disabled={isActioning}
        onClick={_ => handleAction()}
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["normal-case", "leading-none", "py-1", "w-16"]),
          (),
        )}>
        {isActioning
          ? <MaterialUi.CircularProgress size={MaterialUi.CircularProgress.Size.int(18)} />
          : React.string(actionLabel)}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
