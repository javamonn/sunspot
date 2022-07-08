module ContextProvider = {
  include React.Context

  let makeProps = (~value, ~children, ()) =>
    {
      "value": value,
      "children": children,
    }

  let make = React.Context.provider(Contexts_AlertCreateAndUpdateDialog_Context.context)
}

type updateAlertModalState =
  | UpdateAlertModalOpen(AlertModal.Value.t)
  | UpdateAlertModalClosing(AlertModal.Value.t)
  | UpdateAlertModalClosed

type createAlertModalState =
  | CreateAlertModalOpen(option<AlertModal.Value.t>)
  | CreateAlertModalClosing(option<AlertModal.Value.t>)
  | CreateAlertModalClosed

@react.component
let make = (~children) => {
  let {authentication}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let {isQuickbuyTxPending}: Contexts_OpenSeaEventDialog_Context.t = React.useContext(
    Contexts_OpenSeaEventDialog_Context.context,
  )
  let (createAlertModal, setCreateAlertModal) = React.useState(_ => CreateAlertModalClosed)
  let (updateAlertModal, setUpdateAlertModal) = React.useState(_ => UpdateAlertModalClosed)

  let accountSubscriptionQuery = Query_AccountSubscription.GraphQL.Query_AccountSubscription.use(
    ~skip=switch authentication {
    | Authenticated(_) => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) => {accountAddress: accountAddress}
    | _ => {accountAddress: ""}
    },
  )
  let integrationsQuery = Query_IntegrationsByAccountAddress.GraphQL.Query_IntegrationsByAccountAddress.use(
    ~skip=switch authentication {
    | Authenticated(_) if !isQuickbuyTxPending => false
    | _ => true
    },
    switch authentication {
    | Authenticated({jwt: {accountAddress}}) =>
      Query_IntegrationsByAccountAddress.makeVariables(~accountAddress)
    | _ => Query_IntegrationsByAccountAddress.makeVariables(~accountAddress="")
    },
  )
  let enabledAlertRuleCount = Query_EnabledAlertRuleCount.GraphQL.use(
    ~skip=switch authentication {
    | Authenticated(_) if !isQuickbuyTxPending => false
    | _ => true
    },
    (),
  )

  let integrationOptions =
    integrationsQuery.data
    ->Belt.Option.map(Query_IntegrationsByAccountAddress.toAlertRuleDestinationOptions)
    ->Belt.Option.getWithDefault([])
  let accountSubscriptionType =
    accountSubscriptionQuery.data
    ->Belt.Option.flatMap(a => a.accountSubscription)
    ->Belt.Option.map(({type_}) => type_)
  let enabledAlertRuleCount =
    enabledAlertRuleCount.data
    ->Belt.Option.map(d => d.enabledAlertRuleCount)
    ->Belt.Option.getWithDefault(0)

  <ContextProvider
    value={{
      Contexts_AlertCreateAndUpdateDialog_Context.openCreateAlertModal: initialValue =>
        setCreateAlertModal(_ => CreateAlertModalOpen(initialValue)),
      openUpdateAlertModal: value => setUpdateAlertModal(_ => UpdateAlertModalOpen(value)),
    }}>
    {switch createAlertModal {
    | CreateAlertModalOpen(initialValue)
    | CreateAlertModalClosing(initialValue) =>
      <Containers.CreateAlertModal
        initialValue=?{initialValue}
        isOpen={switch createAlertModal {
        | CreateAlertModalOpen(_) => true
        | _ => false
        }}
        onClose={_ =>
          setCreateAlertModal(alertModalValue =>
            switch alertModalValue {
            | CreateAlertModalOpen(v) => CreateAlertModalClosing(v)
            | _ => alertModalValue
            }
          )}
        onExited={_ => setCreateAlertModal(_ => CreateAlertModalClosed)}
        destinationOptions={integrationOptions}
        accountSubscriptionType={accountSubscriptionType}
        alertCount={enabledAlertRuleCount}
      />
    | _ => React.null
    }}
    {switch authentication {
    | Authenticated({jwt: {accountAddress}}) => <>
        <Containers.UpdateAlertModal
          isOpen={switch updateAlertModal {
          | UpdateAlertModalOpen(_) => true
          | _ => false
          }}
          value=?{switch updateAlertModal {
          | UpdateAlertModalOpen(v) | UpdateAlertModalClosing(v) => Some(v)
          | _ => None
          }}
          onExited={_ => setUpdateAlertModal(_ => UpdateAlertModalClosed)}
          onClose={_ =>
            setUpdateAlertModal(alertModalValue =>
              switch alertModalValue {
              | UpdateAlertModalOpen(v) => UpdateAlertModalClosing(v)
              | _ => alertModalValue
              }
            )}
          onDuplicate={() => {
            switch updateAlertModal {
            | UpdateAlertModalOpen(v) =>
              setUpdateAlertModal(_ => UpdateAlertModalClosing(v))
              setCreateAlertModal(_ => CreateAlertModalOpen(Some(v)))
              openSnackbar(
                ~message={React.string("alert rule duplicated, click \"create\" to save.")},
                ~type_=Contexts_Snackbar.TypeWarning,
                ~duration=6000,
                (),
              )
            | _ => ()
            }
          }}
          destinationOptions={integrationOptions}
          accountAddress={accountAddress}
          accountSubscriptionType={accountSubscriptionType}
          alertCount={enabledAlertRuleCount}
        />
      </>
    | _ => React.null
    }}
    {children}
  </ContextProvider>
}
