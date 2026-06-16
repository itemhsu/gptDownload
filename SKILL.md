---
name: chatgpt-share-export
description: >-
  Export a public ChatGPT share link (a chatgpt.com/share/... or chat.openai.com/share/... URL)
  into a clean, self-contained HTML file AND a matching A4 PDF, with the output filenames taken
  from the conversation's own title. Use this whenever the user wants to save, archive, back up,
  print, "存成 PDF/HTML", "印成 PDF", "備份", or otherwise turn a shared ChatGPT conversation into a
  file — especially if it contains uploaded images/screenshots, because ChatGPT does NOT render
  those images to logged-out viewers and a plain browser "print to PDF" silently drops every one
  of them; this skill fetches and embeds them. Trigger whenever a chatgpt.com/share or
  chat.openai.com/share URL appears together with any intent to produce a file (PDF, HTML, "a copy
  I can email/print/keep"), e.g. "把這個 ChatGPT 對話存成 PDF", "save this chatgpt share link as html",
  "archive/backup this shared conversation". Do NOT use it for: share links from OTHER assistants
  (claude.ai/share, g.co/gemini/share — different endpoints, out of scope); merely summarizing or
  answering questions about a share link with no file requested; converting a generic webpage,
  .docx, or local file to PDF; exporting a user's whole ChatGPT account history from settings; or
  capturing the user's own live (non-shared) chat session.
---

# ChatGPT Share → HTML + PDF

Turn a public ChatGPT share link into a self-contained `.html` and an A4 `.pdf`,
both named after the conversation title.

## Why a dedicated tool (don't just print the page)

A logged-out browser viewing a ChatGPT share link **never renders the user's
uploaded images** — they exist only as internal `sediment://file_...` pointers,
and ChatGPT's frontend doesn't resolve them for anonymous visitors. So
"open the page and `page.pdf()`" produces a file with **all the screenshots
missing**, which is the #1 thing people get wrong here.

This skill instead pulls the **structured conversation JSON** from the public
`/backend-anon/share/{id}` endpoint, resolves each image through
`/backend-anon/files/download/...` (which *does* work for anonymous viewers),
inlines the bytes as base64, and renders a clean transcript itself. Images are
always present, and the output never depends on the ~5-minute signed image URLs.

## Usage

The work is done by `scripts/export_share.mjs`. Run it with the share URL:

```bash
SKILL_DIR=~/.claude/skills/chatgpt-share-export   # adjust if installed elsewhere

# One-time (or whenever node_modules is missing): install deps + browser.
# Fast if Chromium is already cached under ~/Library/Caches/ms-playwright.
[ -d "$SKILL_DIR/node_modules" ] || ( cd "$SKILL_DIR" && npm install --no-audit --no-fund )
node -e "require('playwright')" 2>/dev/null || ( cd "$SKILL_DIR" && npx playwright install chromium )

# Export into the user's CURRENT directory (default), filename from the title.
node "$SKILL_DIR/scripts/export_share.mjs" "<share-url>" --outdir "$(pwd)"
```

The script prints progress lines and finishes with a machine-readable line:

```
RESULT {"title":"…","baseName":"…","messages":12,"images":2,"files":["…/Title.html","…/Title.pdf"]}
```

Parse that final `RESULT {…}` line to report exactly what was written.

### Options

- `--outdir DIR` — where to write (default: current working directory).
- `--format pdf,html` — comma list; default is both. Use `--format html` or
  `--format pdf` for just one.
- `--name NAME` — override the auto-derived base filename (still sanitized).
- `--overwrite` — replace existing files. By default the script never clobbers:
  if `<title>.html`/`<title>.pdf` already exist it saves `<title> (2)`, `(3)`, …
  instead, picking one suffix that's free for **both** formats so the pair stays
  matched. Pass `--overwrite` only when the user explicitly wants to replace.

## After running

1. Read the `RESULT` JSON line and tell the user the exact file paths.
2. **Verify the images actually landed** rather than assuming — e.g.
   `pdfimages -list "<file>.pdf"` (if poppler is available) should show one row
   per embedded screenshot, and `images` in the RESULT line should match the
   number of screenshots the conversation has. If `images` is 0 but the user
   expected screenshots, say so — the link may have had its images stripped or
   the conversation genuinely had none.
3. The filename is the sanitized conversation title (CJK characters are kept;
   only `/ \ : * ? " < > |` and control chars are replaced). If the user wants a
   different name, re-run with `--name`.
4. If `RESULT` has `"renamed": true`, an earlier export of the same conversation
   was already there, so this run was saved under a ` (n)` suffix — mention the
   actual filename so the user isn't surprised. They can re-run with `--overwrite`
   to replace the old copy instead.

## Notes & failure modes

- **Link must be public.** Private/expired share links return no data; the
  script exits with "Could not load conversation data".
- **Cloudflare:** the script opens the real share page first so its request
  context carries the cookies the anon backend expects. If the JSON fetch starts
  failing, that handshake is usually why — keep the initial `page.goto`.
- **Branched conversations:** the transcript follows `current_node` up its parent
  chain — the exact thread the share page displays — even when the conversation
  was edited or an answer regenerated.
- This only handles ChatGPT shares. Other providers (Claude, Gemini) have
  different endpoints and are out of scope.
