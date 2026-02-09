# ClaudeR Architecture

## Overview

ClaudeR enables AI coding assistants (Claude Code or OpenCode) to execute R code through RStudio using the Model Context Protocol (MCP). This architecture allows agentic R programming while maintaining RStudio as the execution environment and result viewer.

## Architecture Diagram

```
┌─────────────────────────┐
│   Any Terminal          │
│   $ claude / $ opencode │
└───────────┬─────────────┘
            │
            ↓
┌───────────────────────────────────────┐
│   AI Coding Assistant                 │
│   (Claude Code or OpenCode)           │
│   - Natural language interface        │
│   - Code generation                   │
│   - Result interpretation             │
└───────────┬───────────────────────────┘
            │ MCP (Model Context Protocol)
            ↓
┌───────────────────────────────────────┐
│   MCP Server (Python)                 │
│   persistent_r_mcp.py                 │
│   - Receives commands via stdio       │
│   - Translates to HTTP requests       │
└───────────┬───────────────────────────┘
            │ HTTP (127.0.0.1:8787)
            ↓
┌───────────────────────────────────────┐
│   ClaudeR HTTP Server (R)             │
│   - Receives HTTP POST requests       │
│   - Executes R code                   │
│   - Returns results as JSON           │
└───────────┬───────────────────────────┘
            │ R API calls
            ↓
┌───────────────────────────────────────┐
│   RStudio IDE                         │
│   - R REPL (code execution)           │
│   - Environment (variable inspection) │
│   - Plots (visualization)             │
│   - Console (output)                  │
└───────────────────────────────────────┘
```

## Component Details

### 1. AI Coding Assistant (Interface Layer)

**Implementations:** Claude Code (`.mcp.json`) or OpenCode (`opencode.jsonc`)

**Role:** Primary user interface for R interaction

**Responsibilities:**
- Accept natural language requests
- Generate appropriate R code
- Execute code via MCP tools
- Interpret and present results

**Example interaction:**
```
User: "Create a scatter plot of mpg vs hp from mtcars"
Assistant: [Generates R code] → [Executes via MCP] → [Shows plot]
```

### 2. MCP Server (Translation Layer)

**Location:** `ClaudeR/renv/library/.../ClaudeR/scripts/persistent_r_mcp.py`

**Role:** Bridge between the assistant and RStudio

**Key features:**
- **stdio interface**: Communicates with the assistant via standard input/output
- **HTTP client**: Uses httpx to send requests to RStudio server
- **Tool definitions**: Exposes MCP tools for R operations

**Available MCP tools:**

1. `execute_r` - Execute R code and return text output
2. `execute_r_with_plot` - Execute R code that generates plots
3. `get_r_info` - Get environment information (packages, variables, version)
4. `get_active_document` - Get RStudio active document content
5. `modify_code_section` - Modify code in active RStudio document

**Configuration:**

**Claude Code** (`.mcp.json` in project root):
```json
{
  "mcpServers": {
    "r-studio": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "run", "--with", "httpx", "--with", "mcp",
        "python", "/path/to/persistent_r_mcp.py"
      ]
    }
  }
}
```

**OpenCode** (`opencode.jsonc` in project root):
```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "r-studio": {
      "type": "local",
      "command": [
        "uv", "run",
        "--with", "httpx",
        "--with", "mcp",
        "python", "/path/to/persistent_r_mcp.py"
      ],
      "enabled": true
    }
  }
}
```

**Dependency management:**
- With `uv`: Dependencies loaded automatically via `uv run --with`
- With system Python: Must install `httpx` and `mcp` separately

### 3. ClaudeR HTTP Server (Execution Layer)

**Role:** R code execution engine within RStudio

**Protocol:** HTTP REST API on localhost:8787

**Startup:**
```r
library(ClaudeR)
claudeAddin()  # Opens UI in Viewer pane
# Click "Start Server" button
# Server starts: "HTTP Server running on http://127.0.0.1:8787"
```

**API endpoints:**
- `POST /execute` - Execute R code
- `POST /execute_with_plot` - Execute code and return plot
- `GET /health` - Health check
- `GET /info` - Environment information

**Request format:**
```json
{
  "code": "x <- 1:10\nmean(x)",
  "return_value": true
}
```

**Response format:**
```json
{
  "output": "[1] 5.5",
  "value": 5.5,
  "success": true,
  "plot": null
}
```

### 4. RStudio IDE (Visualization Layer)

**Role:** Result viewer and R environment manager

**Usage patterns:**

**Passive mode (most common):**
- Leave RStudio open in background
- All code execution happens via the assistant
- Check RStudio when you want to inspect:
  - Environment pane: Current variables
  - Plots pane: Generated graphics
  - Console: Execution history
  - Viewer: HTML outputs

**Active mode (optional):**
- Manually write/edit R code in RStudio
- Variables created in RStudio are accessible to the assistant
- Useful for interactive exploration

## Data Flow Example

### User request: "Calculate mean of 1 to 10"

1. **User → Assistant:**
   ```
   User: "Calculate mean of 1 to 10"
   ```

2. **Assistant generates R code:**
   ```r
   x <- 1:10
   mean(x)
   ```

3. **Assistant → MCP Server (stdio):**
   ```json
   {
     "tool": "execute_r",
     "code": "x <- 1:10\nmean(x)"
   }
   ```

4. **MCP Server → ClaudeR HTTP Server:**
   ```http
   POST http://127.0.0.1:8787/execute
   Content-Type: application/json

   {"code": "x <- 1:10\nmean(x)", "return_value": true}
   ```

5. **ClaudeR executes in R:**
   ```r
   eval(parse(text = "x <- 1:10\nmean(x)"))
   # Returns: 5.5
   ```

6. **ClaudeR → MCP Server:**
   ```json
   {
     "output": "[1] 5.5",
     "value": 5.5,
     "success": true
   }
   ```

7. **MCP Server → Assistant:**
   ```json
   {
     "output": "[1] 5.5"
   }
   ```

8. **Assistant → User:**
   ```
   The mean of 1 to 10 is 5.5
   ```

9. **RStudio state updated:**
   - Variable `x` now visible in Environment pane
   - Console shows execution history

## Key Design Decisions

### Why MCP over direct R execution?

**Advantages:**
- **Separation of concerns**: The assistant doesn't need R knowledge
- **Flexibility**: Can swap R backend without changing the assistant
- **Safety**: R code execution is sandboxed in RStudio
- **Monitoring**: Easy to inspect state in RStudio IDE

### Why HTTP for ClaudeR?

**Advantages:**
- **Language agnostic**: Python MCP server talks to R via HTTP
- **RStudio integration**: Leverages existing RStudio infrastructure
- **Debugging**: Can test endpoints with curl/Postman
- **Stateful**: R session persists between requests

### Python dependency options

**uv (Recommended):**
- **No installation needed**: Dependencies loaded on-demand via `uv run --with`
- **No global pollution**: Isolated per execution
- **Fast**: Efficient caching

**System Python:**
- **Simple**: Uses existing Python installation
- **Requires setup**: Must install httpx and mcp packages

**Custom environment:**
- **Flexible**: Use any environment manager (venv, conda, etc.)
- **Controlled**: Pin specific versions

## Security Considerations

### Local-only execution
- Server binds to 127.0.0.1 (localhost only)
- No external network access
- Safe for sensitive data

### Code execution safety
- All R code runs in user's RStudio session
- Same permissions as RStudio process
- User can see/interrupt any execution

### Dependency isolation
- Python dependencies via `uv run --with`
- R packages via renv (project-specific)
- No system-wide modifications required

## Troubleshooting Connection Flow

When `/mcp` or `claude mcp list` (Claude Code), or `/mcps` or `opencode mcp list` (OpenCode) shows r-studio as "failed", debug in this order:

1. **Check RStudio server:**
   ```bash
   curl http://127.0.0.1:8787/health
   ```
   - If fails: RStudio server not running
   - Solution: Start server in RStudio (`claudeAddin()` → "Start Server")

2. **Check MCP server can reach R:**
   ```bash
   python .claude/skills/claude-r/scripts/check_r_connection.py
   ```
   - If fails: Network issue or wrong port
   - Solution: Verify R server is on port 8787

3. **Check Python dependencies:**
   ```bash
   uv run --with httpx --with mcp python -c "import httpx, mcp"
   ```
   - If fails: Missing dependencies
   - Solution: Verify uv is installed and working

4. **Check MCP configuration:**
   ```bash
   # Claude Code
   cat .mcp.json
   # OpenCode
   cat opencode.jsonc
   ```
   - If wrong: Configuration issue
   - Solution: Re-run MCP server registration command (Claude Code) or fix `opencode.jsonc` (OpenCode)
   - Docs: [Claude Code MCP](https://code.claude.com/docs/en/mcp) | [OpenCode MCP](https://opencode.ai/docs/mcp-servers/)

