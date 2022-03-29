@module("date-fns/formatRelative") external formatRelative: (float, float) => string = "default"

@deriving(abstract)
type formatDistanceOptions = {
  @optional includeSeconds: bool,
  @optional addSuffix: bool,
}
@module("date-fns/formatDistance")
external formatDistance: (float, float, formatDistanceOptions) => string = "default"
