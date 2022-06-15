module String = {
  @send external padEnd: (string, int, string) => string = "padEnd"
  @send external padStart: (string, int, string) => string = "padStart"
}
