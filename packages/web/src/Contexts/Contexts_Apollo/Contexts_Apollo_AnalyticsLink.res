exception ErrorAnalyticsLinkGraphQL(string)
exception ErrorAnalyticsLinkDecode(string)

@decco
type operationError = {
  message: string,
  path: array<Js.Json.t>,
  locations: Js.Json.t,
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
    operationResponse.errors->Belt.Option.map(errors => {
      (
        ErrorAnalyticsLinkGraphQL(operation->Externals.ApolloLink.operationName),
        [
          (
            "appsyncErrors",
            errors
            ->Belt.Array.map(error =>
              Js.Json.object_(
                Js.Dict.fromArray([
                  ("message", Js.Json.string(error.message)),
                  ("path", error.path->Js.Json.array),
                  ("locations", error.locations),
                ]),
              )
            )
            ->Js.Json.array,
          ),
          ("operationName", operation->Externals.ApolloLink.operationName->Js.Json.string),
          ("operationVariables", operation->Externals.ApolloLink.variables),
        ],
      )
    })
  | Belt.Result.Error(error) =>
    Some((
      ErrorAnalyticsLinkDecode(error.message),
      [
        ("operationName", operation->Externals.ApolloLink.operationName->Js.Json.string),
        ("operationVariables", operation->Externals.ApolloLink.variables),
        ("operationResponse", operationResponse),
      ],
    ))
  }

  let _ = error->Belt.Option.forEach(((error, extra)) => {
    Services_Logger.exn_(
      ~tag="Contexts_Apollo_AnalyticsLink",
      ~message="operation error",
      ~extra,
      error,
    )
  })
})
