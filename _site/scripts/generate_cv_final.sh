#!/bin/bash

# Final CV generation script with emoji text replacements and all improvements
# Usage: ./scripts/generate_cv_final.sh [email] [linkedin]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INPUT_FILE="_pages/resume_pdf.md"
OUTPUT_FILE="files/pedro_simoes_cv.pdf"
TEMP_FILE="temp_resume_final.md"
TEMPLATE_FILE="templates/cv_template.tex"

# Default contact information (can be overridden by command line args)
DEFAULT_EMAIL="seomisw@gmail.com"
DEFAULT_LINKEDIN="https://pt.linkedin.com/in/pedro-sim%C3%B5es-909719151"

# Parse command line arguments
EMAIL=${1:-$DEFAULT_EMAIL}
LINKEDIN=${2:-$DEFAULT_LINKEDIN}

echo -e "${BLUE}🎯 Final CV PDF Generator${NC}"
echo -e "${BLUE}=============================${NC}"

# Check dependencies
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}❌ Error: pandoc is not installed${NC}"
    echo "Please install pandoc first:"
    echo "  macOS: brew install pandoc"
    echo "  Ubuntu: sudo apt-get install pandoc"
    exit 1
fi

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

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo -e "${YELLOW}📝 Creating final resume with all improvements...${NC}"
echo -e "   Email: ${EMAIL}"
echo -e "   LinkedIn: ${LINKEDIN}"

# Create temporary file with customized content and social icons
cat > "$TEMP_FILE" << 'EOF'
# Pedro Simões
**Software Engineer & Backend Team Leader**
*Caparica, Portugal*

![Mail](images/social-icons/maildotru.pdf){height=1em} EMAIL_PLACEHOLDER

![RSS](images/social-icons/rss.pdf){height=1em} [seomis.cc](https://seomis.cc) • ![GitHub](images/social-icons/github.pdf){height=1em} [psimoesSsimoes](https://github.com/psimoesSsimoes) • ![X](images/social-icons/x.pdf){height=1em} [@seomisw](https://twitter.com/seomisw)

![LinkedIn](images/social-icons/linkedin.pdf){height=1em} [pedro-simões](LINKEDIN_PLACEHOLDER) • ![Reddit](images/social-icons/reddit.pdf){height=1em} [u/seomisS](https://www.reddit.com/user/seomisS) • ![Bluesky](images/social-icons/bluesky.pdf){height=1em} [@its-me-seomis.bsky.social](https://bsky.app/profile/its-me-seomis.bsky.social)

---

**CEO @ Afectos a Si - Caparica, PT**

Hello, I'm Pedro Simões, a dedicated hacker with a great team spirit, passionate about technology and how it shapes our world.

Always thinking about building and maintaining robust distributed systems. My expertise spans the full development lifecycle, from initial design and implementation to ongoing monitoring and the strategic planning of our technical roadmap.

I build software with honesty and openness at my core. No corporate speak—just straightforward communication and genuine effort. When I commit to something, I pour myself into making it exceptional.

What truly energizes me is collaborating with talented, dedicated people tackling difficult problems together. I genuinely believe that when a group of individuals works hard while maintaining a positive, fun spirit, that combination is where innovation truly happens.

I'm always open to connecting with people who value craftsmanship and authenticity.

If you're looking for someone who transforms teams through dedication and technical excellence, don't hesitate to reach out.

---

## Professional Experience

### *Backend Team Leader* @ [Easypay](https://www.easypay.pt/en)
**2021-11 – Present**

We've spent our time making a complex system more stable, more predictable, and easier to work with.

We implemented proper shutdown handling, enforced atomic operations where failure wasn't an option, and built third-party integrations that could scale without drama.

We made observability a priority — adding tests that mattered, metrics that told the truth, and error reporting that helped instead of overwhelmed. We added idempotency and request tracing to make our distributed flows traceable and trustworthy. We dug into access patterns, found what hurt performance or reliability, fixed what we could, and made thoughtful trade-offs when the perfect fix wasn't worth the cost. We invested in each other — through code reviews, mentoring, and honest technical conversations.

We shaped the way the team works: from practical processes to real feedback loops that actually improve things.

When the business came with fast-moving or fuzzy problems, we clarified, prioritized, and shipped solid solutions. Nothing flashy — just steady, deliberate progress that made things better.

### *Senior Software Engineer* @ [Worten](https://www.worten.pt/)
**2020-01 – 2021-10**

Coordinated a team responsible for the implementation of an Identity and Access Management (IAM) system at Worten. This critical system involved strategic planning, integration with existing systems, adherence to regulatory compliance, and management of user groups, roles and permissions. Managed various aspects of the IAM system, including authentication protocols, performance optimization, quality assurance, disaster recovery planning and budget management. My focus on collaboration, communication, and continuous improvement ensured a streamlined process that aligned with organizational goals and industry best practices.

### *Software Engineer* @ [Aubay](https://aubay.pt/)
**2017-01 – 2019-12**

Contracted by Worten, I was an essential member of a high-performing three-person team responsible for the development and maintenance of critical back-end infrastructure for the Worten platform. This involved creating and implementing key components such as the Payment Gateway and Shopping Cart Rule System, both of which are live and fully operational in production today. My role focused on the implementation, continuous performance optimization, and real-time troubleshooting of these systems.

By ensuring they remain reliable, scalable, and efficient, me and my collegues played a key part in maintaining the smooth operation of the e-commerce platform, providing a seamless experience for millions of customers. It was a valuable experience, and I learned a great deal along the way!

### *Software Engineer* @ [UNINOVA](https://www.uninova.pt/)
**2014-03 – 2016-12**

Full-stack developer and system administrator at UNINOVA - Institute for the Development of New Technologies, contributing to multiple research and development projects in industrial automation and software systems.

**Key responsibilities and achievements:**
- **System Administration**: Successfully migrated legacy servers to modern software stacks.
- **Containerization**: Led the migration of multiple applications to Docker, streamlining deployment processes and reducing infrastructure overhead
- **Ruby Development**: Architected and developed the Algerian Teacher Electronics Card System, a nationwide identification and certification platform serving thousands of educators
- **Go Backend Development**: Built the core backend infrastructure for the FITMAN project (Future Internet Technologies for MANufacturing), implementing RESTful APIs and real-time data processing capabilities
- **Cross-functional Collaboration**: Worked closely with research teams to translate academic requirements into production-ready software solutions

---

## Proficient in
- **Languages**: Go, Rust, Elixir, Ruby, Python, Lua
- **Frameworks/Runtimes**: Gin, Node.js
- **Databases**: PostgreSQL, Redis, Kafka, SQLite, MySQL, DynamoDB
- **DevOps & Containerization**: Docker, Kubernetes, GitHub Actions, Continuous Integration, Continuous Delivery
- **Operating Systems**: Ubuntu, Alpine Linux
- **Tools & Technologies**: Git, WebAssembly, HTTP/2, Vim/Neovim
- **AI Assistance**: Local LLM, ChatGPT, GPT4, Copilot, Claude, Gemini
- **Other Skills**: Technical Writing

---

## Academic Background

### Bachelor's Degree in Computer Engineering @ [Universidade de Lisboa](https://www.fct.unl.pt/en)
2013 - 2016

---

*Resume updated: GENERATION_DATE*
EOF

# Replace placeholders with actual values (using pipe delimiter to avoid issues with URLs)
sed -i.bak "s|EMAIL_PLACEHOLDER|${EMAIL}|g" "$TEMP_FILE"
sed -i.bak "s|LINKEDIN_PLACEHOLDER|${LINKEDIN}|g" "$TEMP_FILE"
sed -i.bak "s|GENERATION_DATE|$(date +'%B %Y')|g" "$TEMP_FILE"

# Remove backup file
rm -f "${TEMP_FILE}.bak"

echo -e "${YELLOW}📄 Converting markdown to PDF with optimized settings...${NC}"

# Generate PDF with pandoc using template with embedded icons
pandoc "$TEMP_FILE" \
    -o "$OUTPUT_FILE" \
    --pdf-engine=xelatex \
    --template="$TEMPLATE_FILE" \
    --variable geometry:margin=0.75in \
    --variable fontsize=11pt \
    --variable documentclass=article \
    --variable papersize=a4 \
    --variable colorlinks=true \
    --variable linkcolor=blue \
    --variable urlcolor=blue \
    2>/dev/null || \
pandoc "$TEMP_FILE" \
    -o "$OUTPUT_FILE" \
    --pdf-engine=xelatex \
    --variable geometry:margin=0.75in \
    --variable fontsize=11pt \
    --variable documentclass=article \
    --variable colorlinks=true \
    --variable linkcolor=blue \
    --variable urlcolor=blue \


# Clean up temporary file
rm -f "$TEMP_FILE"

# Check if PDF was created successfully
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${GREEN}✅ PDF generated successfully: $OUTPUT_FILE${NC}"
    echo -e "${GREEN}📊 File size: $(du -h "$OUTPUT_FILE" | cut -f1)${NC}"
    echo -e "${GREEN}📅 Generated on: $(date)${NC}"

    # Show all improvements made
    echo -e "\n${BLUE}🎉 Final Version Features:${NC}"
    echo -e "   ✓ Clean title (no duplicates or metadata shown)"
    echo -e "   ✓ Professional contact information section"
    echo -e "   ✓ All social media platforms included:"
    echo -e "     • GitHub, LinkedIn, Twitter"
    echo -e "     • Reddit, Bluesky, RSS Feed"
    echo -e "   ✓ Social icons properly embedded as PDF vectors"
    echo -e "   ✓ Robust font handling with fallbacks"
    echo -e "   ✓ No download links in PDF"
    echo -e "   ✓ Clean, professional formatting"
    echo -e "   ✓ Optimized for ATS systems"

    # Show usage instructions
    echo -e "\n${BLUE}💡 Usage Examples:${NC}"
    echo -e "   Basic: ./scripts/generate_cv_final.sh"
    echo -e "   Email: ./scripts/generate_cv_final.sh pedro@example.com"
    echo -e "   Full:  ./scripts/generate_cv_final.sh pedro@example.com 'linkedin.com/in/pedro'"
    echo -e "\n${BLUE}🚀 Quick Makefile Usage:${NC}"
    echo -e "   make cv-final EMAIL=pedro@example.com LINKEDIN='linkedin.com/in/pedro'"

else
    echo -e "${RED}❌ Error: Failed to generate PDF${NC}"
    echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
    echo -e "   • Check if pandoc and xelatex are properly installed"
    echo -e "   • Try: brew install pandoc && brew install --cask mactex"
    echo -e "   • Or: sudo apt-get install pandoc texlive-xetex"
    exit 1
fi

echo -e "${GREEN}🎉 Final CV generated successfully!${NC}"
