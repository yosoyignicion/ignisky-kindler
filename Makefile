SHELL := /bin/bash
SCRIPT := src/script.sh

.PHONY: help install uninstall demo audit clean

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  install   Install script to ~/.local/bin/"
	@echo "  uninstall Remove script from ~/.local/bin/"
	@echo "  demo      Run a quick demo of the script"
	@echo "  audit     Run basic security checks"
	@echo "  clean     Remove temporary files"

SCRIPT_NAME := $(notdir $(basename $(SCRIPT)))

install:
	@echo "🔧 Installing script..."
	@mkdir -p $(HOME)/.local/bin
	@cp $(SCRIPT) $(HOME)/.local/bin/$(SCRIPT_NAME)
	@chmod +x $(HOME)/.local/bin/$(SCRIPT_NAME)
	@echo "✅ Installed to ~/.local/bin/$(SCRIPT_NAME)"

uninstall:
	@echo "🗑️  Removing script..."
	@rm -f $(HOME)/.local/bin/$(SCRIPT_NAME)
	@echo "✅ Removed ~/.local/bin/$(SCRIPT_NAME)"

demo:
	@echo "🚀 Running demo..."
	@bash ignisky-kindler.sh --tokens

audit:
	@echo "🛡️ Running basic audit..."
	@bash -n $(SCRIPT) && echo "✅ Syntax OK"
	@command -v shellcheck >/dev/null 2>&1 && shellcheck $(SCRIPT) || echo "⚠️  shellcheck no instalado, sáltate este paso"

clean:
	@rm -rf tmp/ temp/ test_output/
	@echo "🧹 Clean done"
