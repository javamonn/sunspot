@react.component @module("@davatar/react")
external make: (
  ~size: int,
  ~address: string,
  ~provider: Externals_Ethereum.t,
  ~graphApiKey: string=?,
  ~generatedAvatarType: string=?,
) => React.element = "default"

module Jazzicon = {
  @react.component @module("@davatar/react/dist/Jazzicon")
  external make: (~size: int, ~address: string) => React.element = "default"
}
