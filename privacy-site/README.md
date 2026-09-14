# Deploy Cyclus Privacy Policy on Render

Static site folder: `privacy-site/` (serves `index.html` at the site root).

## Option A — Blueprint (recommended)

1. Open [Render Dashboard](https://dashboard.render.com/) → **New** → **Blueprint**
2. Connect GitHub repo **Laurence-26/overy**
3. Render reads `render.yaml` and creates **cyclus-privacy**
4. After deploy, copy the URL (example: `https://cyclus-privacy.onrender.com`)
5. Paste that URL into Google Play Console → App content → Privacy policy

## Option B — Manual Static Site

1. **New** → **Static Site**
2. Connect **Laurence-26/overy**, branch `main`
3. **Root Directory:** `privacy-site`
4. **Build Command:** *(leave empty)*
5. **Publish Directory:** `.`
6. Create Static Site → wait for live URL

## Local preview

Open `privacy-site/index.html` in a browser, or:

```bash
npx --yes serve privacy-site
```
