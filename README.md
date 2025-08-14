# macOS-style Portfolio on Azure Static Web Apps (Automated Starter)

This starter gives you a *working* portfolio site with:
- A macOS-style UI (`index.html`)
- **Admin** upload for your CV (PDF)
- Viewers can only **view** (no edit)
- Azure Functions API under `/api/*`
- Cosmos DB for metadata, Blob Storage for files

## Quick start

1. **Download this repo** (zip) and unzip locally.
2. Install **Azure CLI**: https://learn.microsoft.com/cli/azure/install-azure-cli
3. *(Optional)* Install **SWA CLI**: `npm i -g @azure/static-web-apps-cli`
4. Open a terminal in the project folder and run:

### macOS / Linux
```bash
./provision.sh
```

### Windows (PowerShell)
```powershell
.\provision.ps1
```

The script will:
- Log you into Azure (if needed)
- Create a **resource group**, **storage account**, and **Cosmos DB** (SQL)
- Create a private blob container `uploads`
- Ask for your **Static Web App** name and set the required **environment variables** on it

> If you haven't created the Static Web App yet, open the Azure Portal and create it (connect to your GitHub repo or deploy using `swa deploy`).

## Deploy

- **Using SWA CLI** (local deploy):
  ```bash
  swa deploy --env production --app-location . --api-location api
  ```

- **Using GitHub Actions**:
  Create the SWA from the Azure Portal and connect your GitHub repo. The portal will add a workflow that deploys on every push. In that case, push this folder to GitHub and you're done.

## Configure roles (give yourself admin)

1. In the Azure Portal, open your Static Web App.
2. Go to **Roles / Role management** and **Invite** yourself.
3. Assign the role **`admin`** to your identity (GitHub/Google/Microsoft — whichever you will sign in with).
4. After you sign in on the site via the provider, the **Admin** icon and window appear.

## Environment variables (already set by the scripts)

- `COSMOS_CONNECTION` – Cosmos DB connection string
- `STORAGE_ACCOUNT_NAME` – Storage account name
- `STORAGE_ACCOUNT_KEY` – Storage account key
- `BLOB_CONTAINER` – usually `uploads`

The API reads these settings; the browser never sees them.

## Files you care about

- `index.html` – frontend (includes an Admin window + CV upload)
- `staticwebapp.config.json` – routes + auth rules
- `api/` – Azure Functions:
  - `admin/files/sign-upload` – creates a write SAS for direct browser upload
  - `admin/files/commit` – saves file metadata to Cosmos DB
  - `files/[id]` – returns a read SAS for a file by id
  - `files/latest` – returns the newest published file (viewer link)

## Notes

- The API functions have `authLevel: "anonymous"` on purpose; Static Web Apps enforces roles at the **route level** (see `staticwebapp.config.json`). The `/api/admin/*` routes require `admin`.
- If you prefer **Managed Identity** instead of keys, assign the identity the roles “Storage Blob Data Contributor” on the storage account and use `DefaultAzureCredential` in the API code.
- For articles + links, you can add more containers and functions using the same pattern.
