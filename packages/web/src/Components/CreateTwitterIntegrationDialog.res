module TwitterIntegration = QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.TwitterIntegration
module Mutation_CreateTwitterIntegration = %graphql(`
  mutation CreateTwitterIntegration($input: CreateTwitterIntegrationInput!) {
    twitterIntegration: createTwitterIntegration(input: $input) {
      ...TwitterIntegration
    }
  }
`)

type value = {
  apiKey: string,
  apiSecret: string,
  userAccessToken: string,
  userAccessSecret: string,
}

@react.component
let make = (~isOpen, ~onClose) => {
  let (isActioning, setIsActioning) = React.useState(_ => false)
  let (value, setValue) = React.useState(_ => {
    apiKey: "",
    apiSecret: "",
    userAccessToken: "",
    userAccessSecret: "",
  })
  let (createTwitterOAuthIntegrationMutation, _) = Mutation_CreateTwitterIntegration.use()
  let (isErrorAlertVisible, setIsErrorAlertVisible) = React.useState(_ => false)

  let handleCreate = () => {
    setIsActioning(_ => true)
    let _ =
      createTwitterOAuthIntegrationMutation(
        ~update=({writeQuery, readQuery}, {data}) => {
          data->Belt.Option.forEach(({twitterIntegration}) => {
            let (
              alertRules,
              discordIntegrations,
              slackIntegrations,
              accountSubscription,
              newTwitterIntegrationItems,
            ) = switch readQuery(
              ~query=module(
                QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress
              ),
              QueryRenderers_Alerts_GraphQL.makeVariables(
                ~accountAddress=twitterIntegration.accountAddress,
              ),
            ) {
            | Some(Ok({
                alertRules,
                discordIntegrations,
                slackIntegrations,
                accountSubscription,
                twitterIntegrations: Some({items: Some(items)}),
              })) => (
                alertRules,
                discordIntegrations,
                slackIntegrations,
                accountSubscription,
                Belt.Array.concat([Some(twitterIntegration)], items),
              )
            | _ => (None, None, None, None, [Some(twitterIntegration)])
            }

            let _ = writeQuery(
              ~query=module(
                QueryRenderers_Alerts_GraphQL.Query_AlertRulesAndOAuthIntegrationsByAccountAddress.AlertRulesAndOAuthIntegrationsByAccountAddress
              ),
              ~data={
                alertRules: alertRules,
                accountSubscription: accountSubscription,
                discordIntegrations: discordIntegrations,
                slackIntegrations: slackIntegrations,
                twitterIntegrations: Some({
                  __typename: "TwitterIntegrationConnection",
                  items: Some(newTwitterIntegrationItems),
                }),
              },
              QueryRenderers_Alerts_GraphQL.makeVariables(
                ~accountAddress=twitterIntegration.accountAddress,
              ),
            )
          })
        },
        {
          input: {
            userAuthenticationToken: Some({
              apiKey: value.apiKey,
              apiSecret: value.apiSecret,
              userAccessToken: value.userAccessToken,
              userAccessSecret: value.userAccessSecret,
            }),
            accessToken: None,
          },
        },
      )
      |> Js.Promise.then_(result => {
        switch result {
        | Ok(
            {data: {twitterIntegration}}: ApolloClient__React_Types.FetchResult.t__ok<
              Mutation_CreateTwitterIntegration.Mutation_CreateTwitterIntegration_inner.t,
            >,
          ) =>
          onClose(Some(twitterIntegration))
        | _ => setIsErrorAlertVisible(_ => true)
        }
        setIsActioning(_ => false)
        Js.Promise.resolve()
      })
      |> Js.Promise.catch(error => {
        setIsErrorAlertVisible(_ => true)
        Js.Promise.resolve()
      })
  }

  <MaterialUi.Dialog
    _open={isOpen} onClose={(_, _) => onClose(None)} maxWidth={MaterialUi.Dialog.MaxWidth.md}>
    <MaterialUi.DialogTitle> {React.string("connect twitter")} </MaterialUi.DialogTitle>
    <MaterialUi.DialogContent>
      <InfoAlert
        text={<p className={Cn.make(["whitespace-pre-wrap"])}>
          {React.string(
            "sunspot will tweet alerts as connected account. connecting a twitter account requires a twitter developer account and api project. \n\njoin the sunspot ",
          )}
          <a
            href={Config.discordGuildInviteUrl}
            target="_blank"
            className={Cn.make(["underline", "inline"])}>
            {React.string("discord")}
          </a>
          {React.string(" if you require assistance.")}
        </p>}>
        <ol className={Cn.make(["list-decimal", "list-inside", "p-6", "space-y-4"])}>
          <li>
            <a
              href="https://developer.twitter.com/en/portal/petition/essential/basic-info"
              target="_blank"
              className={Cn.make(["underline", "inline"])}>
              {React.string("create a twitter developer account")}
            </a>
            {React.string(" associated with the account you wish to connect.")}
          </li>
          <li>
            {React.string(
              "once your developer account is created and verified, enter an App name and click \"Get keys\".",
            )}
          </li>
          <li>
            {React.string(
              "copy the values for \"API Key\" and \"API Key Secret\" into the inputs below.",
            )}
          </li>
          <li> {React.string("click \"skip to dashboard\".")} </li>
          <li>
            {React.string(
              "on the project dashboard, setup authentication by clicking \"Set up\" under the \"User authentication settings\" section. click the toggle to enable \"OAuth 1.0a\", click \"Read and write\" under \"App permissions\", and enter \"https://sunspot.gg\" as the value for the \"Callback URI / Redirect URL\" and \"Website URL\" fields.",
            )}
          </li>
          <li>
            {React.string(
              "on the project dashboard, click the \"Keys and tokens\" tab, and under the \"Access Token and Secret\" section, click \"Generate\", and copy the values for \"Access Token\" and \"Access Token Secret\" into the inputs below. ensure that the credentials have been created with \"Read and Write\" permissions.",
            )}
          </li>
        </ol>
      </InfoAlert>
      {isErrorAlertVisible
        ? <MaterialUi_Lab.Alert
            severity=#Error
            classes={MaterialUi_Lab.Alert.Classes.make(~root=Cn.make(["mb-6", "mt-6"]), ())}>
            {React.string(
              "unable to connect to your twitter account. verify that the supplied credentials are correct, and ",
            )}
            <a
              href={Config.discordGuildInviteUrl}
              target="_blank"
              className={Cn.make(["underline"])}>
              {React.string("contact support")}
            </a>
            {React.string(" if the issue persists.")}
          </MaterialUi_Lab.Alert>
        : React.null}
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-6", "w-full"]), ())}>
        <MaterialUi.TextField
          variant=#Filled
          label={React.string("api key")}
          _InputLabelProps={{"shrink": true}}
          value={value.apiKey->MaterialUi.TextField.Value.string}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]
            setValue(value => {...value, apiKey: newValue})
          }}
        />
        <MaterialUi.FormHelperText>
          {React.string("\"API Key\" value under the \"Consumer Keys\" section")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-6", "w-full"]), ())}>
        <MaterialUi.TextField
          variant=#Filled
          label={React.string("api secret")}
          _InputLabelProps={{"shrink": true}}
          value={value.apiSecret->MaterialUi.TextField.Value.string}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]
            setValue(value => {...value, apiSecret: newValue})
          }}
        />
        <MaterialUi.FormHelperText>
          {React.string("\"API Key Secret\" value under the \"Consumer Keys\" section")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-6", "w-full"]), ())}>
        <MaterialUi.TextField
          variant=#Filled
          label={React.string("user access token")}
          _InputLabelProps={{"shrink": true}}
          value={value.userAccessToken->MaterialUi.TextField.Value.string}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]
            setValue(value => {...value, userAccessToken: newValue})
          }}
        />
        <MaterialUi.FormHelperText>
          {React.string("\"Access Token\" value under \"Authentication Tokens\" section")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
      <MaterialUi.FormControl
        classes={MaterialUi.FormControl.Classes.make(~root=Cn.make(["mt-6", "w-full"]), ())}>
        <MaterialUi.TextField
          variant=#Filled
          label={React.string("user access secret")}
          _InputLabelProps={{"shrink": true}}
          value={value.userAccessSecret->MaterialUi.TextField.Value.string}
          onChange={ev => {
            let target = ev->ReactEvent.Form.target
            let newValue = target["value"]
            setValue(value => {...value, userAccessSecret: newValue})
          }}
        />
        <MaterialUi.FormHelperText>
          {React.string("\"Access Secret\" value under \"Authentication Tokens\" section")}
        </MaterialUi.FormHelperText>
      </MaterialUi.FormControl>
    </MaterialUi.DialogContent>
    <MaterialUi.DialogActions>
      <MaterialUi.Button
        variant=#Text
        color=#Primary
        disabled={isActioning}
        onClick={_ => onClose(None)}
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
        onClick={_ => handleCreate()}
        classes={MaterialUi.Button.Classes.make(
          ~label=Cn.make(["normal-case", "leading-none", "py-1", "w-16"]),
          (),
        )}>
        {isActioning
          ? <MaterialUi.CircularProgress size={MaterialUi.CircularProgress.Size.int(18)} />
          : React.string("connect")}
      </MaterialUi.Button>
    </MaterialUi.DialogActions>
  </MaterialUi.Dialog>
}
