# Makefile for CV generation
# Pedro Simões Resume PDF Generator

.PHONY: help cv cv-enhanced cv-filtered cv-improved cv-final clean install-deps check-deps

# Default target
help:
	@echo "📄 Pedro Simões CV Generator"
	@echo "============================"
	@echo ""
	@echo "Available targets:"
	@echo "  cv            - Generate PDF using basic method"
	@echo "  cv-final      - Generate final PDF with custom contact info (recommended)"
	@echo "  clean         - Remove generated files"
	@echo "  install-deps  - Install required dependencies"
	@echo "  check-deps    - Check if dependencies are installed"
	@echo ""
	@echo "Examples:"
	@echo "  make cv"
	@echo "  make cv-final EMAIL=pedro@example.com LINKEDIN='linkedin.com/in/pedro' (RECOMMENDED)"

# Variables with defaults
EMAIL ?= seomisw@gmail.com
LINKEDIN ?= https://pt.linkedin.com/in/pedro-sim%C3%B5es-909719151

# Output file
OUTPUT_FILE = files/pedro_simoes_cv.pdf

# Basic CV generation
cv: check-deps
	@echo "🔄 Generating CV using basic method..."
	./scripts/generate_cv.sh
	@echo "✅ CV generated: $(OUTPUT_FILE)"

# Final CV generation with all improvements (RECOMMENDED)
cv-final: check-deps
	@echo "🔄 Generating final CV (recommended)..."
	@echo "📧 Email: $(EMAIL)"
	@echo "🔗 LinkedIn: $(LINKEDIN)"
	./scripts/generate_cv_final.sh "$(EMAIL)" "$(LINKEDIN)"
	@echo "✅ Final CV generated: $(OUTPUT_FILE)"

# Clean generated files
clean:
	@echo "🧹 Cleaning generated files..."
	rm -f $(OUTPUT_FILE)
	rm -f temp_*.md
	@echo "✅ Cleaned"

# Check dependencies
check-deps:
	@echo "🔍 Checking dependencies..."
	@command -v pandoc >/dev/null 2>&1 || { echo "❌ pandoc is not installed. Run 'make install-deps' or install manually."; exit 1; }
	@command -v xelatex >/dev/null 2>&1 || { echo "❌ xelatex is not installed. Run 'make install-deps' or install manually."; exit 1; }
	@echo "✅ Dependencies check passed"

# Install dependencies (macOS with Homebrew)
install-deps:
	@echo "📦 Installing dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing pandoc..."; \
		brew install pandoc || true; \
		echo "Installing MacTeX (this may take a while)..."; \
		brew install --cask mactex || true; \
		echo "Installing Python dependencies..."; \
		pip3 install panflute || true; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "Installing on Ubuntu/Debian..."; \
		sudo apt-get update; \
		sudo apt-get install -y pandoc texlive-xetex; \
		pip3 install panflute; \
	else \
		echo "❌ Unsupported package manager. Please install manually:"; \
		echo "   - pandoc"; \
		echo "   - texlive-xetex or MacTeX"; \
		echo "   - panflute (pip3 install panflute)"; \
		exit 1; \
	fi
	@echo "✅ Dependencies installed"

# Development helpers
dev-serve:
	@echo "🚀 Starting Jekyll development server..."
	bundle exec jekyll serve --livereload

dev-build:
	@echo "🔨 Building Jekyll site..."
	bundle exec jekyll build

# Quick CV generation with common email patterns
cv-quick:
	@echo "🚀 Quick CV generation..."
	@echo "Enter your email address:"
	@read email; \
	echo "Enter your LinkedIn profile (or press Enter for default):"; \
	read linkedin; \
	linkedin=$${linkedin:-"$(LINKEDIN)"}; \
	./scripts/generate_cv_final.sh "$$email" "$$linkedin"

# Watch for changes and auto-regenerate
watch:
	@echo "👀 Watching for changes in resume files..."
	@echo "Press Ctrl+C to stop..."
	@while true; do \
		inotifywait -e modify _pages/resume.md _pages/resume_pdf.md 2>/dev/null && \
		make cv-enhanced; \
		sleep 2; \
	done || echo "Install inotify-tools for file watching"

# Validate generated PDF
validate:
	@if [ -f "$(OUTPUT_FILE)" ]; then \
		echo "✅ PDF exists: $(OUTPUT_FILE)"; \
		echo "📊 File size: $$(du -h $(OUTPUT_FILE) | cut -f1)"; \
		echo "📅 Last modified: $$(stat -f %Sm $(OUTPUT_FILE) 2>/dev/null || stat -c %y $(OUTPUT_FILE) 2>/dev/null)"; \
	else \
		echo "❌ PDF not found: $(OUTPUT_FILE)"; \
		echo "Run 'make cv' to generate it."; \
		exit 1; \
	fi

# Open generated PDF
open:
	@if [ -f "$(OUTPUT_FILE)" ]; then \
		echo "📖 Opening PDF..."; \
		open "$(OUTPUT_FILE)" 2>/dev/null || xdg-open "$(OUTPUT_FILE)" 2>/dev/null || echo "Please open $(OUTPUT_FILE) manually"; \
	else \
		echo "❌ PDF not found. Run 'make cv' first."; \
		exit 1; \
	fi

# Show file info
info:
	@echo "📋 CV Generation Info"
	@echo "===================="
	@echo "Input files:"
	@echo "  - _pages/resume.md (original)"
	@echo "  - _pages/resume_pdf.md (PDF-specific)"
	@echo ""
	@echo "Output file:"
	@echo "  - $(OUTPUT_FILE)"
	@echo ""
	@echo "Scripts:"
	@echo "  - scripts/generate_cv.sh"
	@echo "  - scripts/generate_cv_final.sh (RECOMMENDED)"
	@echo ""
	@echo "Current settings:"
	@echo "  EMAIL = $(EMAIL)"
	@echo "  LINKEDIN = $(LINKEDIN)"
