@react.component @module("@davatar/react")
external make: (
  ~size: int,
  ~address: string,
  ~provider: Externals_Ethereum.t,
  ~graphApiKey: string=?,
  ~generatedAvatarType: string=?,
) => React.element = "default"
