let styles = %raw("require('./Containers_PromotionClaimModal.module.css')")

type dialogState =
  | Open({
      errorText: option<string>,
      collectionContractAddress: string,
      collectionImageUrl: option<string>,
      collectionName: option<string>,
    })
  | Closed

module AccountSubscription = Query_AccountSubscription.GraphQL.AccountSubscription
module Mutation_ClaimPromotion = %graphql(`
  mutation PromotionClaimModal_ClaimPromotion($input: ClaimPromotionInput!) {
    accountSubscription: claimPromotion(input: $input) {
      ...AccountSubscription
    }
  }
`)

module Query_OpenSeaCollectionByContractAddress = %graphql(`
  query PromotionClaimModal_OpenSeaCollectionByContractAddress($input: OpenSeaCollectionByContractAddressInput!) {
    collection: getOpenSeaCollectionByContractAddress(input: $input) {
      name
      imageUrl
      slug
    }
  }
`)

module PromotionClaimDialog = {
  @react.component
  let make = (~isOpen, ~onClose, ~onClaimClick, ~collectionName=?, ~errorText=?) => {
    let (isClaiming, setIsClaiming) = React.useState(_ => false)

    let handleClaimClick = () => {
      setIsClaiming(_ => true)
      let _ =
        onClaimClick()
        |> Js.Promise.then_(() => {
          setIsClaiming(_ => false)
          Js.Promise.resolve()
        })
        |> Js.Promise.catch(error => {
          setIsClaiming(_ => false)
          Js.Promise.resolve()
        })
    }

    <MaterialUi.Dialog
      _open={isOpen}
      onClose={(_, _) => onClose()}
      maxWidth={MaterialUi.Dialog.MaxWidth.md}
      classes={MaterialUi.Dialog.Classes.make(
        ~paper=Cn.make([
          "sm:w-full",
          "sm:h-full",
          "sm:max-w-full",
          "sm:max-h-full",
          "sm:m-0",
          "sm:rounded-none",
        ]),
        (),
      )}>
      <MaterialUi.DialogTitle
        disableTypography={true}
        classes={MaterialUi.DialogTitle.Classes.make(
          ~root=Cn.make([
            "px-6",
            "pb-0",
            "leading-none",
            "flex",
            "items-center",
            "flex-row",
            "md:px-4",
            "md:pb-4",
            "md:border",
            "md:border-b",
            "md:border-darkBorder",
          ]),
          (),
        )}>
        <MaterialUi.IconButton
          onClick={_ => onClose()}
          size=#Small
          classes={MaterialUi.IconButton.Classes.make(~root=Cn.make(["mr-4"]), ())}>
          <Externals.MaterialUi_Icons.Close />
        </MaterialUi.IconButton>
        <MaterialUi.Typography
          color=#Primary
          variant=#H6
          classes={MaterialUi.Typography.Classes.make(~root=Cn.make(["leading-none", "mt-1"]), ())}>
          {React.string("claim free access")}
        </MaterialUi.Typography>
      </MaterialUi.DialogTitle>
      <MaterialUi.DialogContent
        classes={MaterialUi.DialogContent.Classes.make(
          ~root=Cn.make(["flex", "flex-col", "font-mono", "p-6"]),
          (),
        )}>
        {errorText
        ->Belt.Option.map(errorText =>
          <MaterialUi_Lab.Alert
            severity=#Error
            classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6"]), ())}>
            {React.string(errorText)}
          </MaterialUi_Lab.Alert>
        )
        ->Belt.Option.getWithDefault(React.null)}
        <div className={Cn.make(["flex", "flex-row", "sm:flex-col"])}>
          <div className={Cn.make(["flex-1", "sm:order-2", "sm:flex-none"])}>
            <AccountSubscriptionCard
              title="observatory"
              subtitle="free / 33 days"
              features=[
                "unlimited alerts",
                "push, discord, twitter, and slack alert destinations",
                "quickbuy",
                "customize alert text and formatting",
              ]
              disabled={false}
              onClick={handleClaimClick}
              labelText={isClaiming ? "claiming..." : "claim"}
              isActioning={isClaiming}
            />
          </div>
          <div
            className={Cn.make([
              "flex",
              "flex-col",
              "justify-center",
              "items-center",
              "flex-2",
              "sm:order-1",
              "sm:flex-none",
              "sm:mb-12",
            ])}>
            {switch collectionName {
            | Some(collectionName) =>
              <p className={Cn.make(["whitespace-pre-line", "max-w-sm"])}>
                <span className={Cn.make(["underline", "font-bold"])}>
                  {React.string(collectionName)}
                </span>
                {React.string(" has partnered with ")}
                <span className={Cn.make(["underline", "font-bold"])}>
                  {React.string("sunspot")}
                </span>
                {React.string(" to give you a ")}
                <span className={Cn.make(["underline", "font-bold"])}>
                  {React.string("free 33 days")}
                </span>
                {React.string(
                  " of Observatory access.\n\nsunspot alerts you in real-time when nft marketplace events occur. use sunspot to snipe rare assets, monitor floor prices, create sales bots, and more.\n\nTo get started, connect your wallet and sign a message to verify token ownership.",
                )}
              </p>
            | None =>
              <div className={Cn.make(["flex", "flex-col"])}>
                <MaterialUi_Lab.Skeleton
                  variant=#Text
                  height={MaterialUi_Lab.Skeleton.Height.int(96)}
                  width={MaterialUi_Lab.Skeleton.Width.int(516)}
                />
                <MaterialUi_Lab.Skeleton
                  variant=#Text
                  height={MaterialUi_Lab.Skeleton.Height.int(96)}
                  width={MaterialUi_Lab.Skeleton.Width.int(516)}
                />
                <MaterialUi_Lab.Skeleton
                  variant=#Text
                  height={MaterialUi_Lab.Skeleton.Height.int(96)}
                  width={MaterialUi_Lab.Skeleton.Width.int(516)}
                />
              </div>
            }}
          </div>
        </div>
      </MaterialUi.DialogContent>
    </MaterialUi.Dialog>
  }
}

@react.component
let make = () => {
  let router: Externals.Next.Router.router = Externals.Next.Router.useRouter()
  let {openSnackbar}: Contexts_Snackbar.t = React.useContext(Contexts_Snackbar.context)
  let {signIn, authentication}: Contexts_Auth.t = React.useContext(Contexts_Auth.context)

  let promotionContractAddress =
    router.asPath
    ->Services.Next.parseQuery
    ->Belt.Option.flatMap(q =>
      q->Externals.Webapi.URLSearchParams.get("promotion-contract-address")->Js.Nullable.toOption
    )

  let (claimPromotionMutation, claimPromotionMutationResult) = Mutation_ClaimPromotion.use()
  let collectionQuery = Query_OpenSeaCollectionByContractAddress.use(
    ~skip=switch promotionContractAddress {
    | None => true
    | _ => false
    },
    switch promotionContractAddress {
    | Some(promotionContractAddress) => {input: {contractAddress: promotionContractAddress}}
    | None => {input: {contractAddress: ""}}
    },
  )

  let (dialogState, setDialogState) = React.useState(() =>
    switch promotionContractAddress {
    | Some(promotionContractAddress) =>
      Open({
        collectionContractAddress: promotionContractAddress,
        errorText: None,
        collectionImageUrl: None,
        collectionName: None,
      })
    | None => Closed
    }
  )

  let _ = React.useEffect1(_ => {
    setDialogState(dialogState =>
      switch dialogState {
      | Open(d) =>
        Open({
          ...d,
          collectionName: collectionQuery.data->Belt.Option.flatMap(c => c.collection.name),
        })
      | _ => dialogState
      }
    )

    None
  }, [
    collectionQuery.data
    ->Belt.Option.flatMap(c => c.collection.name)
    ->Belt.Option.getWithDefault(""),
  ])

  let handleClose = () => {
    Externals.Next.Router.replaceWithParams(router, router.pathname, None, {shallow: true})
    setDialogState(_ => Closed)
  }

  let handleClaim = () => {
    signIn() |> Js.Promise.then_((authentication: Contexts_Auth.authentication) =>
      switch (authentication, dialogState) {
      | (Authenticated({jwt: {accountAddress}}), Open({collectionContractAddress})) =>
        claimPromotionMutation(
          ~refetchQueries=[String("AlertRulesAndOAuthIntegrationsByAccountAddress")],
          ~update=({writeQuery}, {data}) => {
            switch data {
            | Some({accountSubscription: Some(accountSubscription)}) =>
              let _ = writeQuery(
                ~query=module(Query_AccountSubscription.GraphQL.Query_AccountSubscription),
                ~data={
                  accountSubscription: Some(accountSubscription),
                },
                Query_AccountSubscription.makeVariables(~accountAddress),
              )
            | _ => ()
            }
          },
          {input: {contractAddress: collectionContractAddress}},
        ) |> Js.Promise.then_(accountSubscription => {
          switch accountSubscription {
          | Ok(
              {data: {accountSubscription: Some(_)}}: ApolloClient__React_Types.FetchResult.t__ok<
                Mutation_ClaimPromotion.Mutation_ClaimPromotion_inner.t,
              >,
            ) =>
            setDialogState(_ => Closed)
            Externals.Next.Router.replaceWithParams(router, router.pathname, None, {shallow: true})
            openSnackbar(
              ~message={React.string("free observatory access claimed.")},
              ~type_=Contexts_Snackbar.TypeSuccess,
              ~duration=6000,
              (),
            )

          | _ =>
            setDialogState(dialogState =>
              switch dialogState {
              | Open(d) =>
                Open({
                  ...d,
                  errorText: Some(
                    "unable to claim observatory access. verify that you own the required token and have not previously claimed free access.",
                  ),
                })
              | d => d
              }
            )
          }

          Js.Promise.resolve()
        })
      | _ => Js.Promise.resolve()
      }
    )
  }

  <PromotionClaimDialog
    isOpen={switch dialogState {
    | Open(_) => true
    | Closed => false
    }}
    onClose={handleClose}
    onClaimClick={handleClaim}
    collectionName=?{switch dialogState {
    | Open({collectionName}) => collectionName
    | _ => None
    }}
    errorText=?{switch dialogState {
    | Open({errorText}) => errorText
    | _ => None
    }}
  />
}
