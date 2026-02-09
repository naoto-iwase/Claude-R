#!/bin/bash
# Automated ClaudeR setup for macOS

set -e

echo "=== ClaudeR Setup ==="
echo ""

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not installed. Install first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi
echo "✅ Homebrew installed"

# Install R
if ! command -v R &> /dev/null; then
    echo "📦 Installing R..."
    brew install r
else
    echo "✅ R already installed"
fi

# Install system dependencies
echo "📦 Installing system dependencies..."
brew install harfbuzz fribidi libtiff jpeg libpng webp libgit2

# Run R setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_R_SCRIPT="$SCRIPT_DIR/setup_claude-r.R"

if [ ! -f "$SETUP_R_SCRIPT" ]; then
    echo "❌ Cannot find setup_claude-r.R at $SETUP_R_SCRIPT"
    exit 1
fi

echo ""
echo "📦 Installing R packages (renv, devtools, ClaudeR)..."
Rscript "$SETUP_R_SCRIPT"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Open RStudio"
echo "2. File -> New Project -> Existing Directory -> select the project folder -> Create Project"
echo "   (If .Rproj already exists, instead: File -> Open Project -> select your .Rproj file -> Open)"
echo "3. Run: library(ClaudeR)"
echo "4. Run: claudeAddin()"
echo "5. Click 'Start Server' in Viewer pane"
echo ""
echo "Then configure MCP with your preferred Python environment:"
echo "See SKILL.md for uv/system Python/custom options"
