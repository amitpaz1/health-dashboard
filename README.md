# Health Dashboard 📊

A personal health analytics dashboard that automatically syncs and visualizes iPhone Health data exported via the Health Auto Export app.

## Features

- **Automated Data Sync**: Downloads new health data files from Google Drive
- **Rich Visualizations**: Interactive charts showing trends and patterns
- **Key Metrics Tracking**: Steps, sleep, heart rate, energy, and more
- **Responsive Design**: Works on desktop and mobile devices
- **Dark Theme**: Easy on the eyes for daily monitoring

## Dashboard Metrics

### Summary Cards
- Daily steps count
- Sleep duration (last night)
- Resting heart rate
- Active energy burned

### Charts
- **Steps Trend**: 30-day line chart showing daily step counts
- **Sleep Breakdown**: 14-day stacked bar chart (deep, REM, core, awake)
- **Heart Metrics**: Dual-axis chart for resting HR and HRV
- **Blood Oxygen**: SpO2 trend over time

## How It Works

1. **Data Collection**: iPhone Health Auto Export app automatically exports daily health data to Google Drive
2. **Data Sync**: The `scripts/sync.sh` script downloads new files and processes them
3. **Data Processing**: `scripts/process.js` aggregates raw JSON files into dashboard format
4. **Visualization**: Static HTML dashboard loads the processed data and renders interactive charts

## Setup

### Prerequisites
- Node.js (for data processing)
- Google Drive API access via `gog` CLI
- Health Auto Export app configured on iPhone

### Installation

1. Clone this repository
2. Set up environment variables:
   ```bash
   export GOG_KEYRING_PASSWORD="$GOG_KEYRING_PASSWORD"  # set in your shell profile
   export GOG_ACCOUNT="your-google-account@gmail.com"
   ```
3. Run initial sync:
   ```bash
   ./scripts/sync.sh
   ```
4. Open `index.html` in a web browser

### Automated Sync

Set up a cron job to run the sync script regularly:

```bash
# Run every hour
0 * * * * cd /path/to/health-dashboard && ./scripts/sync.sh >> logs/sync.log 2>&1
```

## Data Structure

Health data is stored in `data/dashboard.json` with the following structure:

```json
{
  "lastUpdated": "2026-02-02T06:42:26.018Z",
  "data": [
    {
      "date": "2026-02-01",
      "steps": 1514,
      "distance": 0,
      "activeEnergy": 349,
      "exerciseMinutes": 2,
      "restingHR": 71,
      "avgHRV": 25,
      "avgSpO2": 94,
      "sleepTotal": 5.69,
      "sleepDeep": 0.53,
      "sleepREM": 1.18,
      "sleepCore": 3.99,
      "sleepAwake": 1.22,
      "sleepStart": "2026-01-31 22:56:10 +0200",
      "sleepEnd": "2026-02-01 05:50:58 +0200",
      "respiratoryRate": 20.6,
      "walkingSpeed": 2.86
    }
  ]
}
```

## Deployment

### GitHub Pages

1. Push to GitHub repository
2. Enable GitHub Pages in repository settings
3. The GitHub Actions workflow will automatically deploy updates

### Manual Deployment

The dashboard is a static site that can be deployed anywhere:
- Copy `index.html` and `data/` folder to your web server
- Ensure the `data/dashboard.json` file is accessible
- No build process required

## File Structure

```
health-dashboard/
├── data/
│   ├── raw/                    # Raw health JSON files from Google Drive
│   └── dashboard.json          # Processed data for dashboard
├── scripts/
│   ├── sync.sh                # Data sync script
│   └── process.js             # Data processing script
├── .github/workflows/
│   └── pages.yml              # GitHub Pages deployment
├── index.html                 # Main dashboard
├── README.md
└── .gitignore
```

## Contributing

This is a personal health dashboard, but feel free to fork and adapt for your own use case. The architecture is designed to be modular and extensible.

## License

MIT License - feel free to use and modify as needed.