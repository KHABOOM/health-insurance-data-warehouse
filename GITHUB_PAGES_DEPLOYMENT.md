# GitHub Pages Deployment Guide

## Overview

Your marimo dashboard is configured to deploy automatically to GitHub Pages using GitHub Actions.

## Deployment Configuration

### What Gets Deployed

- **File**: `data_marts_dashboard.py`
- **Export Mode**: HTML-WASM (edit mode)
- **Output**: Static website at `https://njaltran.github.io/health-insurance-data-warehouse/`

### Important Notes

Since this is a **static HTML export**, the BigQuery connections will NOT work in the deployed version. The dashboard will display in edit mode where users can:
- View the notebook structure and code
- See the dashboard layout
- Understand how the dashboard is built

**BigQuery queries cannot run in the static deployment** because:
- Static sites can't authenticate with Google Cloud
- No backend server to handle BigQuery API calls
- Browser WASM environment has no access to credentials

## Setup Steps

### 1. Enable GitHub Pages

1. Go to: `https://github.com/njaltran/health-insurance-data-warehouse/settings/pages`
2. Under **"Source"**, select **"GitHub Actions"**
3. Save the settings

### 2. Commit and Push the Workflow

```bash
git add .github/workflows/deploy-marimo-dashboard.yml
git commit -m "Add GitHub Actions workflow to deploy marimo dashboard"
git push
```

### 3. Monitor the Deployment

1. Go to: `https://github.com/njaltran/health-insurance-data-warehouse/actions`
2. Watch the "Deploy marimo Dashboard to GitHub Pages" workflow
3. Once complete (green checkmark), your dashboard is live!

## Workflow Details

The workflow runs on:
- Every push to the `main` branch
- Manual trigger via "Run workflow" button

### Build Steps

1. **Checkout**: Gets your repository code
2. **Setup Python**: Installs Python 3.11
3. **Install Dependencies**: Installs marimo, BigQuery client, pandas, plotly
4. **Export**: Converts notebook to HTML-WASM in edit mode
5. **Upload**: Prepares static files for deployment
6. **Deploy**: Publishes to GitHub Pages

## Accessing Your Dashboard

After deployment completes:
- **URL**: `https://njaltran.github.io/health-insurance-data-warehouse/`
- **Mode**: Edit mode (interactive code cells, read-only)
- **Data**: No live BigQuery data (static export)

## Alternative: Running with Live Data

If you want the dashboard with live BigQuery connections, run it locally:

```bash
source venv/bin/activate
marimo edit data_marts_dashboard.py
```

Or share the molab link (requires GitHub):
```
https://molab.marimo.io/github/njaltran/health-insurance-data-warehouse/blob/main/data_marts_dashboard.py
```

## Troubleshooting

### Workflow Fails

1. Check the Actions tab for error messages
2. Ensure Python dependencies are correctly listed
3. Verify the notebook file has no syntax errors

### Dashboard Doesn't Load

1. Confirm GitHub Pages is set to "GitHub Actions" source
2. Check that deployment completed successfully
3. Wait a few minutes for GitHub Pages to propagate

### Need Live Data Access?

For production use with live BigQuery data, consider:
1. **Google Cloud Run**: Deploy as a live Python app
2. **Local hosting**: Run marimo server on a VM with credentials
3. **Authenticated gateway**: Use a proxy service with BigQuery access

## Files Created

- `.github/workflows/deploy-marimo-dashboard.yml` - GitHub Actions workflow
- `GITHUB_PAGES_DEPLOYMENT.md` - This documentation

---

**Built with marimo + GitHub Actions + GitHub Pages**
