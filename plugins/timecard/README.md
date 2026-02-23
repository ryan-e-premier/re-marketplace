# timecard

Automate filling out your Workday timecard with browser automation.

## Command

```text
/stn:timecard
```

Interactive workflow that:

1. Asks which week (this week or last week)
2. Asks for Admin hours per day
3. Calculates Development hours (8 − Admin per day)
4. Shows a preview and asks for confirmation
5. Automates Chrome to fill the timecard in Workday

The command saves your timecard but does not submit it for approval — you
must still submit through Workday's review process.

## Requirements

- Chrome with the
  [Claude in Chrome](https://github.com/anthropics/claude-in-chrome) extension
  active
- Access to Workday at `myworkday.com/premierinc`
