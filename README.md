# gptDownload

Export a **public ChatGPT share link** into a clean, self-contained **HTML** file
and a matching **A4 PDF** — with the output filenames taken from the
conversation's own title.

Packaged as a [Claude Code](https://claude.com/claude-code) skill (`SKILL.md`),
but the engine (`scripts/export_share.mjs`) is a plain Node script you can run on
its own.

## Why it exists

A logged-out browser viewing a ChatGPT share link **never renders the user's
uploaded images** — they exist only as internal `sediment://file_...` pointers,
and ChatGPT's frontend doesn't resolve them for anonymous visitors. So the
obvious "open the page and print to PDF" silently drops **every screenshot**.

This tool instead pulls the structured conversation from the public
`backend-anon/share/{id}` endpoint, resolves each image through
`backend-anon/files/download/...` (which *does* work for anonymous viewers),
inlines the bytes as base64, and renders its own transcript. Images are always
present, and the output never depends on the short-lived signed image URLs.

## Install

```bash
npm install                 # playwright + marked
npx playwright install chromium   # one-time; downloads the headless shell
```

## Usage

```bash
node scripts/export_share.mjs "https://chatgpt.com/share/<id>"
```

Options:

| Flag | Meaning |
|------|---------|
| `--outdir DIR` | Where to write (default: current directory) |
| `--format pdf,html` | Comma list; default is both |
| `--name NAME` | Override the auto-derived base filename |
| `--overwrite` | Replace existing files (default never clobbers; it saves `Title (2)`, `(3)`, …) |

The script prints a final `RESULT {…}` JSON line with the title, the files
written, and the message/image counts.

## How it works

1. Opens the share page so the request context clears Cloudflare and picks up
   cookies.
2. Fetches the conversation JSON and follows `current_node` up its parent chain —
   the exact thread the share page shows, even for edited/regenerated branches.
3. Resolves and inlines every image concurrently (base64 data URIs).
4. Renders markdown (headings, tables, code, blockquotes) into a clean chat
   layout. A strict `Content-Security-Policy` neutralizes any scripts embedded in
   the conversation when the HTML is opened.
5. Writes `<title>.html` and `<title>.pdf`.

## Scope

ChatGPT shares only. Claude / Gemini shares use different endpoints and are out
of scope.

## Development

This repo doubles as a [Claude Code](https://claude.com/claude-code) skill. The
"installed" copy lives under `~/.claude/skills/chatgpt-share-export/` (with its
`trigger_evals.json` in the sibling `…-workspace/`), separate from this checkout.
A `Makefile` keeps the two in sync:

| Command | Direction |
|---------|-----------|
| `make status` | List which files differ (`=` same / `!=` differ) |
| `make diff` | Full unified diff (installed skill vs repo) |
| `make pull` | installed skill → repo (you edited the live skill) |
| `make push` | repo → installed skill (you edited here) |
| `make publish m="msg"` | `pull`, then `git commit` + `push` |

`node_modules/` is not synced — run `npm install` on each side. If you don't use
Claude Code, ignore all of this and just run `scripts/export_share.mjs` directly.

## License

MIT
