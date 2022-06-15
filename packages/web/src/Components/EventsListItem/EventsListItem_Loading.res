@react.component
let make = (~style) => {
  let isXs = Config.isBreakpointXs()

  <li
    style={style}
    className={Cn.make(["list-none", "flex", "flex-row", "pb-4", "px-4", "cursor-pointer"])}>
    <MaterialUi_Lab.Skeleton
      variant=#Rect
      height={MaterialUi_Lab.Skeleton.Height.int(isXs ? 96 : 128)}
      width={MaterialUi_Lab.Skeleton.Width.int(isXs ? 96 : 128)}
      classes={MaterialUi_Lab.Skeleton.Classes.make(~root=Cn.make(["flex-shrink-0"]), ())}
    />
    <div
      className={Cn.make([
        "px-3",
        "border-t",
        "border-b",
        "border-r",
        "border-solid",
        "border-darkBorder",
        "rounded",
        "py-3",
        "flex",
        "flex-1",
        "flex-col",
        "justify-between",
      ])}>
      <div className={Cn.make(["flex", "flex-1", "flex-col", "justify-start", "items-start"])}>
        <MaterialUi_Lab.Skeleton
          variant=#Text
          height={MaterialUi_Lab.Skeleton.Height.int(isXs ? 18 : 32)}
          width={MaterialUi_Lab.Skeleton.Width.int(isXs ? 120 : 280)}
        />
        <MaterialUi_Lab.Skeleton
          variant=#Text
          height={MaterialUi_Lab.Skeleton.Height.int(isXs ? 14 : 28)}
          width={MaterialUi_Lab.Skeleton.Width.int(isXs ? 60 : 120)}
        />
      </div>
      <div className={Cn.make(["flex", "flex-row", "space-x-4"])}>
        <MaterialUi_Lab.Skeleton
          variant=#Text
          height={MaterialUi_Lab.Skeleton.Height.int(isXs ? 28 : 32)}
          width={MaterialUi_Lab.Skeleton.Width.int(isXs ? 48 : 64)}
        />
        <MaterialUi_Lab.Skeleton
          variant=#Text
          height={MaterialUi_Lab.Skeleton.Height.int(isXs ? 28 : 32)}
          width={MaterialUi_Lab.Skeleton.Width.int(isXs ? 58 : 72)}
        />
      </div>
    </div>
  </li>
}
