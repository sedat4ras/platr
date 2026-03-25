"""
Platr Multi-Agent — Shared State Definition
LangGraph TypedDict state that flows through every node in the StateGraph.
"""

from __future__ import annotations
from typing import TypedDict, Annotated, Sequence, Literal
from langchain_core.messages import BaseMessage
import operator


AgentRole = Literal["lead", "ios", "backend", "osint", "done"]


class PlatrState(TypedDict):
    """Shared mutable state passed between all agents in the graph."""

    # Conversation / task messages visible to all agents
    messages: Annotated[Sequence[BaseMessage], operator.add]

    # Which agent currently holds the token
    current_agent: AgentRole

    # Structured task payload handed off between agents
    task: dict

    # Accumulated artifacts (code files, schema defs, etc.)
    artifacts: dict

    # Error surface — any agent can write here; lead agent monitors it
    errors: list[str]

    # Final output assembled by lead agent
    final_output: dict
