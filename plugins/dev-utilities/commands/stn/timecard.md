# Timecard - Fill out Workday timecard

Automate filling out your Workday timecard with browser automation.

## Usage

```
/timecard
```

Runs the interactive timecard filling workflow.

## Examples

- `/timecard` - Start the interactive workflow

---

## Workflow

### Phase 1: Gather All Information Upfront

1. **Ask user all questions first**
   - Ask: "Is this for this week or last week?"
   - Ask: "How many Admin hours per day?" (format: "Mon: 1, Tue: 0, Wed: 0.5,
     Thu: 0.5, Fri: 2")
   - Parse the Admin hours response

2. **Calculate and display planned hours**
   - Calculate Development hours: 8 - Admin hours for each day
   - Show user the breakdown:
     - **Admin Reg**: Mon: X, Tue: X, Wed: X, Thu: X, Fri: X (Total: X)
     - **Development**: Mon: X, Tue: X, Wed: X, Thu: X, Fri: X (Total: X)
     - **Grand Total**: 40 hours
   - Ask user: "Does this look correct? (yes/no)"
   - If no, ask for corrections and recalculate
   - If yes, proceed to browser automation

### Phase 2: Browser Automation

3. **Get browser context and navigate to Workday**
   - Call `tabs_context_mcp` to get available tabs
   - Create new tab if needed
   - Navigate to: https://www.myworkday.com/premierinc/d/home.htmld
   - Dismiss any session recovery dialogs

4. **Access timecard entry**
   - Click "Enter My Time" button
   - Wait for timecard page to load
   - Take screenshot to see current state

5. **Navigate to correct week**
   - If "last week": Click the "<" (previous) button to go to previous week
   - Take screenshot to confirm correct week is displayed

6. **Navigate to Enter Time by Type**
   - Click "Actions" button
   - Select "Enter Time by Type"
   - Wait for page to load

7. **Add time type rows**
   - Click "Add Row" button to create first row
   - Enter time type: "Admin Reg" (search and select "Admin Reg > General
     Phase > Admin Reg")
   - Click "Add Row" button again to create second row
   - Enter time type: "Clinical Decision Support" (navigate through: Project
     Plan Tasks > Clinical Decision Support Platform > General Phase >
     Development)
   - Press Escape to close any open dropdowns
   - Take screenshot showing both rows added

8. **Fill Development hours**
   - Click on Monday field in Development row
   - Enter the calculated Development hours for each day using Tab to move
     between fields
   - Example: If Mon=7, Tue=8, Wed=7.5, Thu=7.5, Fri=6, enter those values
   - Click elsewhere to deselect and let totals update

9. **Fill Admin hours**
   - Click on Monday field in Admin Reg row
   - Enter Admin hours for each day using Tab to move between fields
   - If a day has 0 Admin hours, press Tab twice to skip that field
   - Click elsewhere to deselect and let totals update

10. **Save changes**
    - Click "Save" button (NOT "Save and Close" yet)
    - Wait for save confirmation and totals to update
    - Take screenshot to verify all hours are correct
    - Verify bottom row totals show 40 hours

11. **Submit timecard**
    - Ask user for final confirmation: "Ready to save and close? (yes/no)"
    - Click "Save and Close" button
    - Wait for page to return to calendar view
    - Take final screenshot showing "Your changes have been saved" message

### Phase 3: Confirm and Document

12. **Inform user about next steps**
    - Show success message with final hour breakdown
    - **IMPORTANT**: Tell user: "Your timecard has been SAVED but not yet
      SUBMITTED. You still need to SUBMIT it through Workday for approval."
    - Remind user to check the calendar view and click the "Review" button if
      they need to submit for approval

13. **Optional: Document the process**
    - Can create `timecard-filling-steps.md` in current directory if needed
    - Log which week was filled and final hour breakdown

## Important Notes

- **Gather ALL information before starting browser automation** - Ask about
  week and Admin hours upfront
- **Show calculated hours for user confirmation** - Display the breakdown and
  get approval before entering anything
- **Never auto-submit without explicit user confirmation**
- **"Save and Close" does NOT submit for approval** - User must still submit
  through Workday's review process
- Total hours must equal 40 for the week (Mon-Fri, 8 hours per day)
- Admin hours are subtracted from Development hours
- Use Tab key to navigate between fields efficiently
- Click "Save" first to verify totals, then "Save and Close" after
  confirmation
- If any step fails, pause and ask user for guidance
- When entering decimal hours (like 0.5), type them as "0.5" not ".5"

## Time Types Used

1. **Admin Reg** - Administrative time (varies per day based on user input)
2. **Clinical Decision Support > Platform > General Phase > Development** -
   Development work (8 hours per day minus Admin hours)

## Hour Calculation

- Start with 8 hours Development per weekday (40 total)
- User provides Admin hours per day
- Admin hours are added to "Admin Reg" row
- Same Admin hours are subtracted from "Development" row
- Final total should always be 40 hours

## Troubleshooting Tips

- **Dropdowns not closing**: Press Escape or click elsewhere on the page
- **Totals not updating**: Click "Save" button to force recalculation
- **Session recovery dialog**: Click "Not Now" to dismiss it
- **Tab skipping fields**: Some fields may be hidden; press Tab twice to skip
- **Totals showing wrong numbers**: Workday may take a moment to recalculate;
  wait and refresh if needed

## Common Issues

1. **Time Type not found**: Use the search function and navigate through the
   folder structure (Project Plan Tasks > Clinical Decision Support Platform >
   General Phase > Development)
2. **Total shows incorrect number**: Click "Save" to force Workday to
   recalculate totals
3. **Friday hours not saving**: Click elsewhere after entering to deselect the
   field before saving
4. **Decimal hours not accepted**: Make sure to type "0.5" not ".5" for half
   hours

---

Execute the timecard filling workflow following the steps above.
