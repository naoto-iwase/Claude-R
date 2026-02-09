#!/usr/bin/env python3
# /// script
# requires-python = ">=3.8"
# dependencies = ["httpx"]
# ///
"""Check if RStudio ClaudeR server is running and accessible."""

import httpx
import sys

R_ADDIN_URL = "http://127.0.0.1:8787"

def check_connection():
    """Check if the R server is accessible."""
    try:
        response = httpx.get(f"{R_ADDIN_URL}/health", timeout=2.0)
        if response.status_code == 200:
            print(f"✅ R server is running at {R_ADDIN_URL}")
            return True
        else:
            print(f"⚠️  R server responded with status {response.status_code}")
            return False
    except httpx.ConnectError:
        print(f"❌ Cannot connect to R server at {R_ADDIN_URL}")
        print("\nTo start the R server:")
        print("1. Open RStudio")
        print("2. File -> New Project -> Existing Directory -> select the project folder -> Create Project")
        print("   (If .Rproj already exists, instead: File -> Open Project -> select your .Rproj file -> Open)")
        print("3. Run: library(ClaudeR)")
        print("4. Run: claudeAddin()")
        print("5. Click 'Start Server' in the Viewer pane")
        return False
    except Exception as e:
        print(f"❌ Error checking connection: {e}")
        return False

if __name__ == "__main__":
    success = check_connection()
    sys.exit(0 if success else 1)
