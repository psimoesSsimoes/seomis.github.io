#!/bin/bash

# Script to generate Pedro Simões CV PDF
# Usage: ./scripts/generate_cv.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INPUT_FILE="_pages/resume_pdf.md"
OUTPUT_FILE="files/pedro_simoes_cv.pdf"
TEMP_FILE="temp_resume.md"
TEMPLATE_FILE="templates/cv_template.tex"

echo -e "${YELLOW}🔄 Generating CV PDF...${NC}"

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}❌ Error: pandoc is not installed${NC}"
    echo "Please install pandoc first:"
    echo "  macOS: brew install pandoc"
    echo "  Ubuntu: sudo apt-get install pandoc"
    exit 1
fi

# Check if xelatex is available
if ! command -v xelatex &> /dev/null; then
    echo -e "${RED}❌ Error: xelatex is not installed${NC}"
    echo "Please install TeX Live or MacTeX first:"
    echo "  macOS: brew install --cask mactex"
    echo "  Ubuntu: sudo apt-get install texlive-xetex"
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}❌ Error: Input file $INPUT_FILE not found${NC}"
    exit 1
fi

# Check if template file exists (optional - will use default if not found)
if [ -f "$TEMPLATE_FILE" ]; then
    TEMPLATE_ARG="--template=$TEMPLATE_FILE"
    echo -e "${YELLOW}📋 Using custom template: $TEMPLATE_FILE${NC}"
else
    TEMPLATE_ARG=""
    echo -e "${YELLOW}📋 Using default pandoc template${NC}"
fi

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Generate PDF with pandoc
echo -e "${YELLOW}📄 Converting markdown to PDF...${NC}"

pandoc "$INPUT_FILE" \
    -o "$OUTPUT_FILE" \
    --pdf-engine=xelatex \
    $TEMPLATE_ARG \
    --variable geometry:margin=1in \
    --variable fontsize=11pt \
    --variable documentclass=article \
    --variable colorlinks=true \
    --variable linkcolor=blue \
    --variable urlcolor=blue

# Check if PDF was created successfully
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${GREEN}✅ PDF generated successfully: $OUTPUT_FILE${NC}"
    echo -e "${GREEN}📊 File size: $(du -h "$OUTPUT_FILE" | cut -f1)${NC}"
else
    echo -e "${RED}❌ Error: Failed to generate PDF${NC}"
    exit 1
fi

# Optional: Open the PDF (uncomment if desired)
# echo -e "${YELLOW}📖 Opening PDF...${NC}"
# open "$OUTPUT_FILE" 2>/dev/null || xdg-open "$OUTPUT_FILE" 2>/dev/null || echo "Please open $OUTPUT_FILE manually"

echo -e "${GREEN}🎉 Done!${NC}"
