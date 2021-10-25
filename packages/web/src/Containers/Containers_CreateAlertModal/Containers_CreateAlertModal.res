let styles = %raw("require('./Containers_CreateAlertModal.module.css')")

module Query_OpenSeaCollectionsByNamePrefix = %graphql(`
  query OpenSeaCollectionsByNamePrefix($input: OpenSeaCollectionsByNamePrefixInput!) {
    collections: openSeaCollectionsByNamePrefix(input: $input) {
      items {
        name
        slug
        imageUrl
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
  }
  let make = t
  external unsafeFromJs: Js.t<'a> => t = "%identity"
}

@react.component
let make = (~isOpen, ~onClose) => {
  let (autocompleteIsOpen, setAutocompleteIsOpen) = React.useState(_ => false)
  let (collectionNamePrefix, setCollectionNamePrefix) = React.useState(_ => "")
  let (collection, setCollection) = React.useState(_ => None)
  let (validationError, setValidationError) = React.useState(_ => None)
  let (
    executeCollectionNamePrefixQuery,
    collectionNamePrefixQueryResult,
  ) = Query_OpenSeaCollectionsByNamePrefix.useLazy()
  let throttledExecuteCollectionNamePrefixQuery = React.useMemo0(() =>
    Externals.Lodash.Throttle1.make(
      (. collectionNamePrefix) =>
        executeCollectionNamePrefixQuery({input: {namePrefix: collectionNamePrefix}}),
      200,
    )
  )
  let (rules, setRules) = React.useState(_ => Belt.Map.String.empty)

  let handleExited = () => {
    setRules(_ => Belt.Map.String.empty)
    setCollectionNamePrefix(_ => "")
    setValidationError(_ => None)
    setCollection(_ => None)
  }
  let handleRuleChange = rule => {
    setRules(rules => rules->Belt.Map.String.set(rule->CreateAlertRule.Price.id, rule))
  }
  let handleRuleRemove = ruleId => {
    setRules(rules => rules->Belt.Map.String.remove(ruleId))
  }
  let handleValidate = () => {
    let collectionValid = Js.Option.isSome(collection)
    let rulesValid =
      rules
      ->Belt.Map.String.valuesToArray
      ->Belt.Array.every(rule =>
        rule
        ->CreateAlertRule.Price.value
        ->Belt.Option.flatMap(Belt.Float.fromString)
        ->Belt.Option.map(value => value >= 0.0)
        ->Belt.Option.getWithDefault(false)
      )

    let result = if !collectionValid {
      Some("collection is required.")
    } else if !rulesValid {
      Some("price rule value must be a positive number.")
    } else {
      None
    }

    setValidationError(_ => result)
    result
  }

  let handleCreate = () =>
    switch handleValidate() {
    | None => onClose()
    | Some(_) => ()
    }

  let _ = React.useEffect1(() => {
    if Js.String2.length(collectionNamePrefix) > 0 {
      throttledExecuteCollectionNamePrefixQuery(. collectionNamePrefix)
    }
    None
  }, [collectionNamePrefix])

  let collectionOptions = switch collectionNamePrefixQueryResult {
  | Unexecuted(_) | Executed({loading: true}) => []
  | Executed({data: Some({collections: Some({items: Some(itemConnections)})})}) =>
    itemConnections->Belt.Array.keepMap(itemConnection =>
      itemConnection->Belt.Option.map(itemConnection =>
        CollectionOption.make(
          ~name=itemConnection.name,
          ~slug=itemConnection.slug,
          ~imageUrl=itemConnection.imageUrl,
        )
      )
    )
  | _ => []
  }

  let (isLoading, loadingText) = switch collectionNamePrefixQueryResult {
  | Unexecuted(_) => (true, React.string("Filter by name..."))
  | Executed({loading: true}) => (true, React.string("Loading..."))
  | _ => (false, React.null)
  }

  <MaterialUi.Dialog
    _open={isOpen}
    onClose={(_, _) => onClose()}
    onExited={_ => handleExited()}
    classes={MaterialUi.Dialog.Classes.make(~paper=styles["dialogPaper"], ())}>
    <MaterialUi.DialogTitle> {React.string("create alert")} </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent
      classes={MaterialUi.DialogContent.Classes.make(~root=Cn.make(["flex", "flex-col"]), ())}>
      {validationError
      ->Belt.Option.map(errorText =>
        <MaterialUi_Lab.Alert
          severity=#Error classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
          {React.string(errorText)}
        </MaterialUi_Lab.Alert>
      )
      ->Belt.Option.getWithDefault(React.null)}
      <MaterialUi_Lab.Autocomplete
        classes={MaterialUi_Lab.Autocomplete.Classes.make(~paper=Cn.make(["bg-gray-100"]), ())}
        _open={autocompleteIsOpen}
        value={MaterialUi_Types.Any(Js.Null.fromOption(collection))}
        onChange={(_, collection, _) => {
          setCollection(_ => collection->Obj.magic)
        }}
        onInputChange={(_, collectionNamePrefix, _) => {
          setCollectionNamePrefix(_ => collectionNamePrefix)
        }}
        getOptionLabel={opt =>
          opt->CollectionOption.nameGet->Belt.Option.getWithDefault("Unnamed Collection")}
        onOpen={_ => setAutocompleteIsOpen(_ => true)}
        onClose={(_, _) => setAutocompleteIsOpen(_ => false)}
        loading={isLoading}
        getOptionSelected={(opt1, opt2) =>
          Obj.magic(CollectionOption.slugGet(opt1) == CollectionOption.slugGet(opt2))}
        options={collectionOptions->Belt.Array.map(c => MaterialUi_Types.Any(c))}
        loadingText={loadingText}
        renderInput={params =>
          React.cloneElement(
            <MaterialUi.TextField label={React.string("collection")} variant=#Outlined />,
            params,
          )}
        renderOption={(opt, _) => <>
          <MaterialUi.Avatar>
            {switch CollectionOption.imageUrlGet(opt) {
            | Some(imageUrl) => <img src=imageUrl />
            | None => React.null
            }}
          </MaterialUi.Avatar>
          <MaterialUi.ListItemText
            classes={MaterialUi.ListItemText.Classes.make(~root=Cn.make(["ml-4"]), ())}
            primary={opt
            ->CollectionOption.nameGet
            ->Belt.Option.getWithDefault("Unnamed Collection")
            ->React.string}
            secondary={React.string(CollectionOption.slugGet(opt))}
          />
        </>}
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
      {rules
      ->Belt.Map.String.valuesToArray
      ->Belt.Array.map(rule =>
        <CreateAlertRule.Price
          key={CreateAlertRule.Price.id(rule)}
          value={rule}
          onChange={handleRuleChange}
          onRemove={() => handleRuleRemove(CreateAlertRule.Price.id(rule))}
        />
      )
      ->React.array}
      {Belt.Map.String.size(rules) == 0
        ? <CreateAlertRule.Prompt onCreate={handleRuleChange} className={Cn.make(["mt-8"])} />
        : React.null}
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions
      classes={MaterialUi.DialogActions.Classes.make(~root=Cn.make(["mt-8"]), ())}>
      <MaterialUi.Button
        variant=#Text
        color=#Primary
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
        onClick={_ => handleCreate()}
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["normal-case", "leading-none", "py-1"]),
          (),
        )}>
        {React.string("create")}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
