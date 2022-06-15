module Throttle1 = {
  type t<'a, 'b> = (. 'a) => 'b
  @send external flush: t<'a, 'b> => unit = "flush"
  @module
  external make: ((. 'a) => 'b, int) => t<'a, 'b> = "lodash/throttle"
}

module Throttle2 = {
  type t<'a, 'b, 'c> = (. 'a, 'b) => 'c
  @send external flush: t<'a, 'b, 'c> => unit = "flush"
  @module
  external make: ((. 'a, 'b) => 'c, int) => t<'a, 'b, 'c> = "lodash/throttle"
}

module Debounce1 = {
  type t<'a, 'b> = (. 'a) => 'b
  @send external flush: t<'a, 'b> => unit = "flush"
  @module
  external make: ((. 'a) => 'b, int) => t<'a, 'b> = "lodash/debounce"
}

@module external sortBy: (array<'a>, 'a => 'b) => array<'a> = "lodash/sortBy"
