"""
Model Context Protocol (MCP) Server for SkillBridge Career Intelligence.
Exposes database tools for job search applications, follow-ups, and match scores.

Usage:
    - Standalone Stdio (for Claude Desktop / Cursor / Antigravity):
        python -m app.services.mcp_server
    - In-process programmatic access:
        from app.services.mcp_server import mcp, execute_mcp_tool
"""

import json
import logging
import os
import sys

# Ensure backend root is on sys.path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

try:
    from mcp.server.mcpserver import MCPServer
    mcp = MCPServer("SkillBridgeCareerServer")
except ImportError:
    try:
        from mcp.server.fastmcp import FastMCP
        mcp = FastMCP("SkillBridgeCareerServer")
    except ImportError:
        # Fallback dummy class if mcp package is missing in some environments
        class _DummyMCP:
            def tool(self):
                def decorator(f):
                    return f
                return decorator
            def run(self):
                print("MCP SDK not installed.")
        mcp = _DummyMCP()

from app.db.session import SessionLocal
from app.services import career_tools

logger = logging.getLogger("mcp_server")


@mcp.tool()
def get_today_applied_jobs(user_id: int = 1) -> str:
    """
    Fetch the number and detailed list of jobs the user applied to today.
    Returns JSON containing total count and list of applied job titles, companies, and dates.
    """
    with SessionLocal() as db:
        data = career_tools.get_today_applied_jobs(db, user_id=user_id)
        return json.dumps(data, indent=2)


@mcp.tool()
def get_today_follow_ups(user_id: int = 1) -> str:
    """
    Fetch job applications that the user needs to follow up on today (or are overdue).
    Returns JSON containing count, as_of_date, and details of pending follow-ups.
    """
    with SessionLocal() as db:
        data = career_tools.get_today_follow_ups(db, user_id=user_id)
        return json.dumps(data, indent=2)


@mcp.tool()
def get_all_follow_ups(user_id: int = 1) -> str:
    """
    Fetch the full list of all scheduled job follow-ups for the user across past, present, and future dates.
    Returns JSON containing full follow-up schedule and days until due.
    """
    with SessionLocal() as db:
        data = career_tools.get_all_follow_ups(db, user_id=user_id)
        return json.dumps(data, indent=2)


@mcp.tool()
def get_high_match_jobs(user_id: int = 1, min_score: int = 50) -> str:
    """
    Fetch job descriptions analyzed by the user where the match score is >= min_score (default 50%).
    Returns JSON containing count and matched job profiles sorted by score descending.
    """
    with SessionLocal() as db:
        data = career_tools.get_high_match_jobs(db, user_id=user_id, min_score=min_score)
        return json.dumps(data, indent=2)


@mcp.tool()
def get_overall_standing(user_id: int = 1) -> str:
    """
    Calculate average match score across all analyzed job descriptions and fetch application statistics.
    Returns JSON with total_analyzed, average_score, highest/lowest scores, and pending follow-ups count.
    """
    with SessionLocal() as db:
        data = career_tools.get_overall_standing(db, user_id=user_id)
        return json.dumps(data, indent=2)


def execute_mcp_tool(name: str, arguments: dict, user_id: int = 1) -> dict:
    """
    Executes an MCP tool programmatically and returns the parsed dictionary result.
    Useful for backend agent services calling MCP tools directly.
    """
    args = dict(arguments or {})
    args.setdefault("user_id", user_id)

    tools_map = {
        "get_today_applied_jobs": get_today_applied_jobs,
        "get_today_follow_ups": get_today_follow_ups,
        "get_all_follow_ups": get_all_follow_ups,
        "get_high_match_jobs": get_high_match_jobs,
        "get_overall_standing": get_overall_standing,
    }

    fn = tools_map.get(name)
    if not fn:
        return {"error": f"Tool '{name}' not found on MCP Server"}

    try:
        raw_result = fn(**args)
        if isinstance(raw_result, str):
            return json.loads(raw_result)
        return raw_result
    except Exception as exc:
        logger.exception("Error executing MCP tool %s: %s", name, exc)
        return {"error": str(exc)}


if __name__ == "__main__":
    # Runs the standard MCP stdio transport loop
    print("Starting SkillBridge MCP Server on stdio...", file=sys.stderr)
    mcp.run()
