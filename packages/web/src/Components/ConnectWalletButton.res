@react.component
let make = (~onClick) => {
  <MaterialUi.Button variant=#Outlined color=#Primary onClick={onClick}>
    {React.string("Connect Wallet")}
  </MaterialUi.Button>
}
