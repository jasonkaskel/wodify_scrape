# wodify_scrape

This is an MVP which scrapes Wodify for workout data for a given date range. It simply outputs as CSV data the date of the workout and all of the text entered for the workout, separated into separate cells by each HTML tag.

## Usage

You'll first need to setup a `.env.development.local` file with the following config params in it based on your Wodify session data. You can get this by inspecting your valid browser request (i.e. from Chrome developer tools) to a "calender date change" operation.

From the request cookie you need:
`AuthenticationToken`

From the request body you need:
`__OSVSTATE`
`AthleteTheme_wtLayout$block$wtSubNavigation$wtWhiteboardProgram`

however for these last two we need to first base64 encode them as JSON. In total, your `.env.development.local` file should look like

AuthenticationToken=your-authentication-token
BASE64_ENCODED_BODY_JSON=base64({"__OSVSTATE":"...","AthleteTheme_wtLayout$block$wtSubNavigation$wtWhiteboardProgram":"..."})

Once your environment is properly setup, you can simply run as:

```
ruby wodify_scrape.rb
```

to output the most recent workout as CSV data. You can also specify a date range to output multiple workouts:

```
ruby wodify_scrape.rb --from 2015-01-01 --to 2015-12-31 > /path/to/workout.csv
```

### Future Features
At some point this repo will probably include tools for analyzing workout data, instead of just giving you a ton of tokens to parse through.
