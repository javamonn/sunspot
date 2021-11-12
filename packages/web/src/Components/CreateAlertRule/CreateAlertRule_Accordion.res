@react.component
let make = (~className=?, ~summaryIcon, ~summaryTitle, ~summaryDescription, ~details) => {
  <MaterialUi.Accordion
    variant=#Outlined classes={MaterialUi.Accordion.Classes.make(~root=?className, ())}>
    <MaterialUi.AccordionSummary
      expandIcon={<Externals.MaterialUi_Icons.ExpandMore />}
      classes={MaterialUi.AccordionSummary.Classes.make(
        ~content=Cn.make(["flex", "items-center"]),
        (),
      )}>
      {summaryIcon}
      <div className={Cn.make(["flex", "flex-col", "ml-4"])}>
        <MaterialUi.Typography variant=#Body1 color=#Primary>
          {summaryTitle}
        </MaterialUi.Typography>
        <MaterialUi.Typography variant=#Body2 color=#Secondary>
          {summaryDescription}
        </MaterialUi.Typography>
      </div>
    </MaterialUi.AccordionSummary>
    <MaterialUi.AccordionDetails> {details} </MaterialUi.AccordionDetails>
  </MaterialUi.Accordion>
}
