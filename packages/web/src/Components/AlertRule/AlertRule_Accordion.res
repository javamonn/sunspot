@react.component
let make = (
  ~className=?,
  ~summaryIcon,
  ~summaryTitle,
  ~summaryDescription,
  ~initialExpanded=false,
  ~renderDetails,
) => {
  let (expanded, setExpanded) = React.useState(_ => initialExpanded)

  <MaterialUi.Accordion
    variant=#Outlined
    classes={MaterialUi.Accordion.Classes.make(~root=?className, ())}
    expanded={expanded}
    onChange={(_, isExpanded) => {setExpanded(_ => isExpanded)}}>
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
        <MaterialUi.Typography
          variant=#Body2
          classes={MaterialUi.Typography.Classes.make(~body2=Cn.make(["text-darkSecondary"]), ())}>
          {summaryDescription}
        </MaterialUi.Typography>
      </div>
    </MaterialUi.AccordionSummary>
    <MaterialUi.AccordionDetails> {renderDetails(~expanded)} </MaterialUi.AccordionDetails>
  </MaterialUi.Accordion>
}
