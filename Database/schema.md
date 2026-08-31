# DataTracking — Database Schema

Two **separate Azure Database for MySQL** databases, both wired via
`MySqlConnector` (NuGet package) with connection strings in `Web.config`.
Both are currently **dummy placeholders** — replace host/database/credentials
before go-live.

```xml
<!-- Web.config -->
<add name="LoginDb" connectionString="Server=login-db.mysql.database.azure.com;Port=3306;Database=access;Uid=REPLACE_ME;Pwd=REPLACE_ME;SslMode=Required;" providerName="MySqlConnector" />
<add name="AppDb"   connectionString="Server=datatracking-db.mysql.database.azure.com;Port=3306;Database=datatracking;Uid=REPLACE_ME;Pwd=REPLACE_ME;SslMode=Required;" providerName="MySqlConnector" />
```

## 1. Identity — JWT / query string + LoginDb

The app never stores identity itself. It arrives from outside:

- **Token + Role**: the user is directed into the app either with a JWT
  (`?jwt=...`, containing `token`/`role` claims) or a plain query string
  (`?token=...&role=...`). `Scripts/auth.js` (`DTAuth.resolve()`) reads
  whichever is present, on every entry page, and caches both in
  `sessionStorage` so pages reached without a query string still have them.
  **Role is shown as-is from the JWT/query string** — the app does not look
  it up or store it anywhere.
- **Name**: resolved server-side from `Token` via the org's existing
  `login_tokenpass` table in the **`access`** database (LoginDb), read-only,
  by `Helpers/LoginDb.cs` — `Dashboard.aspx.cs`'s `GetUserInfo` WebMethod
  calls it on every Dashboard load.

| Table | Columns used | Notes |
| --- | --- | --- |
| `login_tokenpass` (LoginDb / `access`) | `Token`, `Name` | This app does not own or create this table, only reads from it by `Token`. |

## 2. App-owned tables — AppDb (`schema.sql`, MySQL DDL)

| Table | Purpose |
| --- | --- |
| `Categories` | 4-level department → category → sub-category → type tree. Self-referencing via `ParentId`, `ON DELETE CASCADE`. Managed from **Master** (`Master.aspx`). |
| `CategoryLevels` | Admin-editable display names for the 4 levels (defaults: Department/Category/Sub-Category/Type). Renamed inline from Master's column headings (pencil icon); the new name is then shown everywhere (Upload, Repository, Master) via `Scripts/auth.js` `applyCategoryLabels()`. Self-heals (create+seed) via `Helpers/AppDb.EnsureCategoryLevelsTable`. |
| `Subjects` | Distinct subject lines typed on Upload, reused for autocomplete. |
| `Tags` | Master tag list, reused for autocomplete. |
| `SubjectTags` | Tags historically used with a subject — powers "related tags" suggestions. |
| `Records` | One row per uploaded item: `Token` (uploader), classification path (`CategoryId`s), subject, remark, timestamp. `RecordId` is a 32-char hex GUID (no dashes), matching the on-disk upload folder name. |
| `RecordFiles` | Files attached to a record — GUID-based stored name, original name, extension, size. |
| `RecordTags` | Many-to-many: tags applied to a record. |

All reads/writes (`Upload.aspx.cs`, `Repository.aspx.cs`, `Master.aspx.cs`,
`UploadHandler.ashx.cs`, `FileHandler.ashx.cs`, `Dashboard.aspx.cs`) go
straight to AppDb via `Helpers/AppDb.cs` — no local JSON files, no hardcoded
data.

See `Database/schema.sql` for full column definitions, types, and indexes.

## 3. Still to do

- Point `AppDb` and `LoginDb` at the real Azure MySQL instances and run
  `schema.sql` against `AppDb` (LoginDb's `login_tokenpass` already exists).
- Confirm the real JWT's claim names for token/role match what
  `Scripts/auth.js` reads (`token`, `role` — case-sensitive as issued).
