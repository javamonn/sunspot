exception ErrorAnalyticsLinkGraphQL(string)
exception ErrorAnalyticsLinkDecode(string)

@decco
type operationError = {
  message: string,
  path: array<Js.Json.t>,
  locations: Js.Json.t,
  errorType: string,
}

@decco
type operationResponse = {
  data: option<Js.Json.t>,
  errors: option<array<operationError>>,
}

let makeApolloLink = onOperation =>
  Externals.ApolloLink.make((operation, forward) => {
    forward(operation)
    ->Externals.ApolloLink.Observable.map(data => {
      onOperation(operation, data)
      data
    })
    ->Js.Option.some
  })

let link = makeApolloLink((operation, operationResponse) => {
  let _ = Services_Logger.logWithData(
    "Contexts_Apollo_AnalyticsLink",
    "operation",
    Js.Json.object_(
      Js.Dict.fromArray([
        ("operationName", operation->Externals.ApolloLink.operationName->Js.Json.string),
        ("variables", operation->Externals.ApolloLink.variables),
      ]),
    ),
  )

  let error = switch operationResponse_decode(operationResponse) {
  | Belt.Result.Ok(operationResponse) =>
    operationResponse.errors->Belt.Option.flatMap(errors => {
      let filteredErrors = errors->Belt.Array.keepMap(error =>
        if (
          error.errorType === "Unauthorized" &&
            operation->Externals.ApolloLink.operationName === "AlertRulesAndOAuthIntegrationsByAccountAddress"
        ) {
          None
        } else {
          [
            ("message", Js.Json.string(error.message)),
            ("path", error.path->Js.Json.array),
            ("locations", error.locations),
          ]
          ->Js.Dict.fromArray
          ->Js.Json.object_
          ->Js.Option.some
        }
      )

      if Js.Array2.length(filteredErrors) > 0 {
        Some((
          operation->Externals.ApolloLink.operationName,
          [
            ("appsyncErrors", filteredErrors->Js.Json.array),
            ("operationName", operation->Externals.ApolloLink.operationName->Js.Json.string),
            ("operationVariables", operation->Externals.ApolloLink.variables),
          ],
        ))
      } else {
        None
      }
    })
  | Belt.Result.Error(error) =>
    Some((
      error.message,
      [
        ("operationName", operation->Externals.ApolloLink.operationName->Js.Json.string),
        ("operationVariables", operation->Externals.ApolloLink.variables),
        ("operationResponse", operationResponse),
      ],
    ))
  }

  let _ = error->Belt.Option.forEach(((errorText, extra)) => {
    Services_Logger.jsExn(
      ~tag="Contexts_Apollo_AnalyticsLink",
      ~message="operation error",
      ~extra,
      Externals.Raw.makeExn(errorText),
    )
  })
})
