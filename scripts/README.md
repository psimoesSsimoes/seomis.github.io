# CV Generation Scripts

This directory contains scripts to generate a PDF version of Pedro Simões' resume from the markdown source, with automatic exclusion of download links and inclusion of contact information.

## Available Scripts

### 1. `generate_cv.sh` - Basic PDF Generation
The simplest approach using a dedicated PDF markdown file.

```bash
./scripts/generate_cv.sh
```

**Features:**
- Uses `_pages/resume_pdf.md` as source
- Clean separation between web and PDF versions
- Manual contact information editing

### 2. `generate_cv_enhanced.sh` - Enhanced with Custom Contact Info
Advanced version with customizable contact information via command line.

```bash
# Basic usage
./scripts/generate_cv_enhanced.sh

# With custom email
./scripts/generate_cv_enhanced.sh your.email@example.com

# Full customization
./scripts/generate_cv_enhanced.sh "pedro@example.com" "+351 123 456 789" "linkedin.com/in/pedrosimoes"
```

**Features:**
- Dynamic contact information injection
- Professional table formatting
- Automatic date stamping
- Better PDF styling

### 3. `generate_cv_filtered.sh` - Filtered from Original Resume
Uses the original `resume.md` file with automatic link filtering.

```bash
# Basic usage
./scripts/generate_cv_filtered.sh

# With custom contact info
./scripts/generate_cv_filtered.sh "pedro@example.com" "+351 123 456 789" "linkedin.com/in/pedrosimoes"
```

**Features:**
- Uses original `_pages/resume.md` file
- Automatic download link removal via Python filter
- Maintains single source of truth
- Dynamic contact information

### 4. `generate_cv_final.sh` - Final Version (RECOMMENDED)
The most complete version with all fixes and improvements.

```bash
# Basic usage
./scripts/generate_cv_final.sh

# With custom email
./scripts/generate_cv_final.sh your.email@example.com

# Full customization
./scripts/generate_cv_final.sh "pedro@example.com" "+351 123 456 789" "linkedin.com/in/pedrosimoes"
```

**Features:**
- ✅ Clean title (no duplicate metadata)
- ✅ Professional contact information section
- ✅ All social media platforms included (GitHub, LinkedIn, Twitter, Reddit, Bluesky, RSS)
- ✅ Emoji-friendly formatting (text replacements)
- ✅ Robust font handling with fallbacks
- ✅ No download links in PDF
- ✅ ATS-optimized formatting

## Prerequisites

### Required Software
- **pandoc**: Document converter
  ```bash
  # macOS
  brew install pandoc
  
  # Ubuntu/Debian
  sudo apt-get install pandoc
  ```

- **XeLaTeX**: PDF engine
  ```bash
  # macOS
  brew install --cask mactex
  
  # Ubuntu/Debian
  sudo apt-get install texlive-xetex
  ```



## File Structure

```
scripts/
├── README.md                    # This file
├── generate_cv.sh              # Basic PDF generation
└── generate_cv_final.sh        # Advanced generation (RECOMMENDED)
```

## Generated Output

All scripts generate: `files/pedro_simoes_cv.pdf`

## Customization

### Contact Information
The enhanced and filtered scripts accept three optional parameters:
1. **Email address**: Professional email
2. **Phone number**: Contact phone (include country code)
3. **LinkedIn profile**: LinkedIn URL path

### PDF Styling
All scripts use these pandoc settings:
- Margin: 0.8 inches
- Font size: 11pt
- Font family: Arial
- Blue hyperlinks
- Professional formatting

## Workflow Integration

### Manual Generation
Run any script when you update your resume:
```bash
./scripts/generate_cv_enhanced.sh "your.email@example.com"
```

### Automated Generation (GitHub Actions)
You can automate PDF generation on resume updates:

```yaml
# .github/workflows/generate-cv.yml
name: Generate CV PDF
on:
  push:
    paths:
      - '_pages/resume.md'
      - '_pages/resume_pdf.md'

jobs:
  generate-pdf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y pandoc texlive-xetex
          pip3 install panflute
      - name: Generate PDF
        run: |
          ./scripts/generate_cv_enhanced.sh "${{ secrets.EMAIL }}" "${{ secrets.PHONE }}" "${{ secrets.LINKEDIN }}"
      - name: Commit PDF
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add files/pedro_simoes_cv.pdf
          git commit -m "Auto-update CV PDF" || exit 0
          git push
```

## Troubleshooting

### Common Issues

1. **`pandoc: command not found`**
   - Install pandoc using the instructions above

2. **`xelatex: command not found`**
   - Install XeLaTeX/MacTeX using the instructions above

3. **`panflute module not found`**
   - Install with: `pip3 install panflute`

4. **Permission denied**
   - Make scripts executable: `chmod +x scripts/*.sh`

5. **Font not found errors**
   - The scripts will fall back to default fonts if Arial isn't available
   - Install Arial or modify the font settings in the scripts

### PDF Quality Issues
- Increase DPI: Add `--variable geometry:margin=0.5in` for more content
- Different fonts: Modify `--variable mainfont="FontName"`
- Link colors: Adjust `--variable linkcolor=color`

## Recommended Approach

For most users, **`generate_cv_final.sh`** (or `make cv-final`) is the best choice as it includes all improvements:
- ✅ Clean title (no duplicate metadata)
- ✅ All social media platforms included
- ✅ Emoji-friendly formatting
- ✅ Professional contact information
- ✅ No download links in PDF
- ✅ Robust font handling with fallbacks
- ✅ ATS-optimized formatting

**Quick Start:**
```bash
make cv-final EMAIL="your.email@example.com" PHONE="+351 123 456 789"
```

**Alternative options:**
- Use `generate_cv_enhanced.sh` for simpler customization needs
- Use `generate_cv_filtered.sh` if you prefer to maintain only the original `resume.md` file