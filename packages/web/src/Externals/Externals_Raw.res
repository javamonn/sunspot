let isBrave: unit => Js.Promise.t<bool> = %raw(
  "() => window.navigator.brave ? window.navigator.brave.isBrave() : Promise.resolve(false)"
)
