import pytest
from app.services.mcp_server import mcp, execute_mcp_tool


@pytest.mark.anyio
async def test_mcp_server_lists_all_tools():
    tools = await mcp.list_tools()
    tool_names = [t.name for t in tools]

    expected = [
        "get_today_applied_jobs",
        "get_today_follow_ups",
        "get_all_follow_ups",
        "get_high_match_jobs",
        "get_overall_standing",
    ]
    for exp in expected:
        assert exp in tool_names, f"Expected MCP tool '{exp}' not found in registered tools"


def test_execute_mcp_tool_locally():
    res = execute_mcp_tool("get_overall_standing", {}, user_id=1)
    assert "total_analyzed" in res or "error" not in res


def test_execute_mcp_tool_unknown():
    res = execute_mcp_tool("non_existent_tool", {}, user_id=1)
    assert "error" in res
