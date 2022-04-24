@module("date-fns/formatRelative") external formatRelative: (float, float) => string = "default"

@deriving(abstract)
type formatDistanceOptions = {
  @optional includeSeconds: bool,
  @optional addSuffix: bool,
}
@module("date-fns/formatDistance")
external formatDistance: (float, float, formatDistanceOptions) => string = "default"

@deriving(abstract)
type formatDistanceStrictOptions = {
  @optional addSuffix: bool,
  @as("unit") @optional unit_: string,
  @optional roundingMethod: string,
}

@module("date-fns/formatDistanceStrict")
external formatDistanceStrict: (float, float, formatDistanceStrictOptions) => string = "default"
