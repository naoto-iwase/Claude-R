---
name: claude-r
description: Execute R code through RStudio via MCP. Use for R programming tasks, statistical analysis, data visualization, or setting up/troubleshooting the RStudio integration with Claude Code or OpenCode.
---

# Claude-R - Execute R through RStudio

Connect an AI coding assistant (Claude Code or OpenCode) to RStudio, enabling agentic R programming. RStudio acts as the execution engine; the assistant generates and runs the code.

OpenCode discovers this skill from `.claude/skills/` just like Claude Code ([docs](https://opencode.ai/docs/skills/)). The MCP config is written to `.mcp.json` (Claude Code) or `opencode.jsonc` (OpenCode).

**Note:** All commands in this document assume the working directory is the project root.

## Quick Start

### Prerequisites Check

Verify RStudio server is running:

```bash
uv run .claude/skills/claude-r/scripts/check_r_connection.py
# or with system Python (if httpx installed)
python .claude/skills/claude-r/scripts/check_r_connection.py
```

If not running:
1. Open RStudio
2. File → New Project → Existing Directory → select the project folder → Create Project
   - If `.Rproj` already exists: File → Open Project → select your `.Rproj` file → Open
3. Run: `library(ClaudeR)`
4. Run: `claudeAddin()`
5. Click "Start Server" in Viewer pane

### Basic Usage

Execute R code:
```r
x <- 1:10
mean(x)
```

Generate plots:
```r
library(ggplot2)
ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
  geom_point(size = 3) +
  theme_minimal()
```

## Available MCP Tools

### execute_r
Execute R code and return text output.

### execute_r_with_plot
Execute R code that generates graphics. Returns PNG image.

### get_r_info
Query R environment:
- `what: "packages"` - Installed packages
- `what: "variables"` - Workspace objects
- `what: "version"` - R version
- `what: "all"` - Complete summary

### get_active_document
Retrieve currently open file in RStudio.

### modify_code_section
Modify code in active RStudio document by pattern or line range.

## Setup and Installation

### Step 1: Install R and Dependencies

```bash
bash .claude/skills/claude-r/scripts/setup_claude-r.sh
```

This installs:
- R via Homebrew
- System dependencies (harfbuzz, libtiff, libgit2, etc.)
- R packages (renv, devtools, ClaudeR)

### Step 2: Configure MCP Client

1. Get the MCP server script path:
   ```bash
   Rscript -e 'cat(system.file("scripts/persistent_r_mcp.py", package="ClaudeR"))'
   ```

2. Determine which client the user is using. If unclear, ask the user.

3. Ask the user which Python environment to use for running the MCP server. Options:
   - `uv` (recommended — no pre-install needed)
   - System Python (`python3`)
   - Other (conda, venv, pyenv, etc.)

   If the user chooses a custom environment, adapt the command/path accordingly. The MCP server script requires `httpx` and `mcp` packages.

4. Register the MCP server:

   **Claude Code** (`claude mcp add` writes to `.mcp.json`):

   With `uv`:
   ```bash
   claude mcp add -s project r-studio -- \
     uv run --with httpx --with mcp python <script path>
   ```

   With system Python (install `httpx` and `mcp` first):
   ```bash
   python3 -m pip install --user httpx mcp
   claude mcp add -s project r-studio -- \
     python3 <script path>
   ```

   With custom environment (example: conda):
   ```bash
   conda install httpx mcp
   claude mcp add -s project r-studio -- \
     /path/to/conda/env/bin/python <script path>
   ```

   Docs: <https://code.claude.com/docs>

   **OpenCode** (write `opencode.jsonc` in the project root):

   With `uv`:
   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "mcp": {
       "r-studio": {
         "type": "local",
         "command": [
           "uv", "run",
           "--with", "httpx",
           "--with", "mcp",
           "python", "<script path>"
         ],
         "enabled": true
       }
     }
   }
   ```

   With system Python:
   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "mcp": {
       "r-studio": {
         "type": "local",
         "command": ["python3", "<script path>"],
         "enabled": true
       }
     }
   }
   ```

   With custom environment (adapt command to the Python binary path):
   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "mcp": {
       "r-studio": {
         "type": "local",
         "command": ["/path/to/env/bin/python", "<script path>"],
         "enabled": true
       }
     }
   }
   ```

   Docs: <https://opencode.ai/docs>

### Step 3: Start R Server

Relay the following instructions to the user exactly as written:

1. Open RStudio
2. File → New Project → Existing Directory → select the project folder → Create Project
   - If `.Rproj` already exists: File → Open Project → select your `.Rproj` file → Open
3. Run `library(ClaudeR)` in the R console
4. Run `claudeAddin()` in the R console
5. Click "Start Server" in the Viewer pane

### Step 4: Verify

**Claude Code:** Run `/mcp` in Claude Code, or `claude mcp list` from the terminal. "r-studio" should show "connected".

**OpenCode:** Run `/mcps` in OpenCode, or `opencode mcp list` from the terminal. "r-studio" should show "connected".

If the server does not appear or shows "failed", ask the user to restart the client and try again. If the issue persists, see [references/troubleshooting.md](references/troubleshooting.md).

## Architecture

Three-layer system:

1. **AI Coding Assistant** (Claude Code or OpenCode): Natural language interface
2. **MCP Server**: Python bridge (stdio ↔ HTTP)
3. **ClaudeR HTTP Server**: R execution in RStudio (port 8787)

RStudio acts passively. Users interact with the assistant, which generates and executes R code. RStudio's Environment, Plots, and Console panes show results.

See [references/architecture.md](references/architecture.md) for details.

## Troubleshooting

If R code execution fails, check connection:

```bash
uv run .claude/skills/claude-r/scripts/check_r_connection.py
```

Common issues:
- RStudio server not running
- MCP configuration incorrect
- Python dependencies missing

See [references/troubleshooting.md](references/troubleshooting.md) for complete guide.

## Key Features

- **State persistence**: R session persists across executions
- **RStudio integration**: View variables, plots, and console in RStudio
- **Agentic**: Generate and execute R code through conversation

## Limitations

- **Single-threaded**: Sequential execution only
- **Local only**: Server binds to localhost
- **RStudio required**: Must be running with server active
- **No streaming**: Results return after complete execution

## Resources

- [Troubleshooting Guide](references/troubleshooting.md) - Connection issues, setup errors
- [Architecture](references/architecture.md) - System design and data flow
- [Setup Script](scripts/setup_claude-r.sh) - Automated installation
- [Connection Checker](scripts/check_r_connection.py) - Verify server status
- [ClaudeR GitHub](https://github.com/IMNMV/ClaudeR) - Original project

### Client Documentation

- [Claude Code docs](https://code.claude.com/docs)
- [OpenCode docs](https://opencode.ai/docs)
