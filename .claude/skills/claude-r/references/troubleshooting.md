# Troubleshooting ClaudeR

## Connection Issues

### MCP Server Shows "failed"

**Symptoms:** When running `/mcp`, the r-studio server shows status "failed"

**Causes:**
1. Python dependencies (httpx, mcp) not installed
2. RStudio server not running
3. Incorrect Python path in configuration

**Solutions:**

1. **Check if dependencies are available:**
   ```bash
   uv run --with httpx --with mcp python -c "import httpx, mcp; print('Dependencies OK')"
   ```

2. **Verify RStudio server is running:**
   - Open RStudio
   - File → New Project → Existing Directory → select the project folder → Create Project
     - If `.Rproj` already exists: File → Open Project → select your `.Rproj` file → Open
   - Run: `library(ClaudeR)`
   - Run: `claudeAddin()`
   - Click "Start Server" in Viewer pane
   - Look for: "HTTP Server running on http://127.0.0.1:8787"

3. **Test connection directly:**
   ```bash
   python .claude/skills/claude-r/scripts/check_r_connection.py
   ```

4. **Check MCP configuration:**
   ```bash
   cat .mcp.json
   ```

   Should show:
   ```json
   {
     "mcpServers": {
       "r-studio": {
         "type": "stdio",
         "command": "uv",
         "args": [
           "run",
           "--with",
           "httpx",
           "--with",
           "mcp",
           "python",
           "/path/to/ClaudeR/renv/library/.../ClaudeR/scripts/persistent_r_mcp.py"
         ]
       }
     }
   }
   ```

### ModuleNotFoundError: No module named 'httpx'

**Cause:** Python environment missing required packages

**Solutions:**

**Option A: Switch to uv (Recommended)**
```bash
claude mcp remove r-studio
claude mcp add -s project r-studio -- \
  uv run --with httpx --with mcp python \
  /path/to/persistent_r_mcp.py
```

**Option B: Install packages in current environment**
```bash
python3 -m pip install --user httpx mcp
```

### RStudio Terminal: claude: command not found

**Cause:** RStudio terminal uses bash but claude is in zsh PATH

**Solution:** Change RStudio terminal to zsh:
1. Tools → Global Options → Terminal
2. Set "New terminals open with" to `/bin/zsh`
3. Restart RStudio or open new terminal

## R Package Installation Issues

### textshaping installation failed

**Error:** `fatal error: 'hb-ft.h' file not found`

**Solution:** Install system dependencies:
```bash
brew install harfbuzz fribidi
```

### ragg installation failed

**Error:** `fatal error: 'tiffio.h' file not found`

**Solution:** Install image processing libraries:
```bash
brew install libtiff jpeg libpng webp
```

### gert installation failed

**Error:** `fatal error: 'git2.h' file not found`

**Solution:** Install libgit2:
```bash
brew install libgit2
```

### General installation strategy

For any R package that fails to compile:
1. Read the error message for missing header files (.h files)
2. Install the corresponding Homebrew package
3. Retry installation

Common mappings:
- Missing `.h` file → Homebrew package
- `hb-ft.h`, `harfbuzz` → `brew install harfbuzz`
- `tiffio.h` → `brew install libtiff`
- `git2.h` → `brew install libgit2`
- `png.h` → `brew install libpng`
- `jpeglib.h` → `brew install jpeg`

## Setup Issues

### ClaudeR package not found

**Error:** `Error in library(ClaudeR) : there is no package called 'ClaudeR'`

**Solution:** Install ClaudeR:
```r
devtools::install_github("IMNMV/ClaudeR")
```

### renv restore fails

**Solution:** Start fresh:
```r
renv::deactivate()
renv::init()
devtools::install_github("IMNMV/ClaudeR")
renv::snapshot()
```

