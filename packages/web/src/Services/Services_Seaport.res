let client = ref(None)

let getClient = provider =>
  switch client.contents {
  | Some(c) => c
  | None =>
    let c = Externals_Seaport.makeClient(provider)
    client.contents = Some(c)
    c
  }
