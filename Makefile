# Sync the source between this repo and the installed Claude Code skill.
#
#   repo:  $(REPO)            (this git checkout — what gets published)
#   skill: $(SKILL)           (the live, installed skill Claude actually runs)
#   evals: $(WORKSPACE)       (trigger_evals.json lives in the skill workspace)
#
# Typical use:
#   make status     # show which files differ between the two copies
#   make diff       # full unified diff (skill vs repo)
#   make pull       # installed skill  -> repo   (you edited the live skill)
#   make push       # repo -> installed skill    (you edited in the repo)
#   make publish m="msg"   # pull, then git commit + push to GitHub

SKILL     := $(HOME)/.claude/skills/chatgpt-share-export
WORKSPACE := $(HOME)/.claude/skills/chatgpt-share-export-workspace
REPO      := $(CURDIR)

# Files whose repo path == skill path.
PAIRS := SKILL.md NOTES.md package.json package-lock.json scripts/export_share.mjs
# The evals file maps to a different location, handled on its own.
EVALS_REPO  := evals/trigger_evals.json
EVALS_SKILL := $(WORKSPACE)/trigger_evals.json

.DEFAULT_GOAL := help

help: ## Show this help
	@echo "gptDownload sync — targets:"
	@awk 'BEGIN{FS=":.*## "} /^[a-zA-Z_-]+:.*## /{printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "  repo : $(REPO)"
	@echo "  skill: $(SKILL)"

status: ## Show which files differ between repo and installed skill
	@for f in $(PAIRS); do \
	  if cmp -s "$(REPO)/$$f" "$(SKILL)/$$f"; then echo "  =  $$f"; else echo "  != $$f"; fi; \
	done
	@if cmp -s "$(REPO)/$(EVALS_REPO)" "$(EVALS_SKILL)"; then \
	  echo "  =  $(EVALS_REPO)"; else echo "  != $(EVALS_REPO)"; fi

diff: ## Full unified diff (installed skill vs repo)
	@for f in $(PAIRS); do \
	  diff -u "$(REPO)/$$f" "$(SKILL)/$$f" || true; \
	done
	@diff -u "$(REPO)/$(EVALS_REPO)" "$(EVALS_SKILL)" || true

pull: ## Copy installed skill -> repo
	@for f in $(PAIRS); do \
	  mkdir -p "$(REPO)/$$(dirname "$$f")"; \
	  cp -p "$(SKILL)/$$f" "$(REPO)/$$f" && echo "  <- $$f"; \
	done
	@mkdir -p "$(REPO)/evals"
	@cp -p "$(EVALS_SKILL)" "$(REPO)/$(EVALS_REPO)" && echo "  <- $(EVALS_REPO)"
	@echo "Pulled installed skill -> repo."

push: ## Copy repo -> installed skill
	@for f in $(PAIRS); do \
	  mkdir -p "$(SKILL)/$$(dirname "$$f")"; \
	  cp -p "$(REPO)/$$f" "$(SKILL)/$$f" && echo "  -> $$f"; \
	done
	@mkdir -p "$(WORKSPACE)"
	@cp -p "$(REPO)/$(EVALS_REPO)" "$(EVALS_SKILL)" && echo "  -> $(EVALS_REPO)"
	@echo "Pushed repo -> installed skill."

m ?= sync skill source
publish: pull ## Pull from skill, then git commit + push (override message with m="...")
	@git -C "$(REPO)" add -A
	@if git -C "$(REPO)" diff --cached --quiet; then \
	  echo "Nothing to commit — already in sync."; \
	else \
	  git -C "$(REPO)" commit -m "$(m)" && git -C "$(REPO)" push && echo "Published."; \
	fi

.PHONY: help status diff pull push publish
