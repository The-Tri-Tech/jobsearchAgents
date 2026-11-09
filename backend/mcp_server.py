"""
Entry point for running the SkillBridge Career MCP Server.

To run:
    cd backend
    .venv/bin/python mcp_server.py
"""

from app.services.mcp_server import mcp

if __name__ == "__main__":
    mcp.run()
