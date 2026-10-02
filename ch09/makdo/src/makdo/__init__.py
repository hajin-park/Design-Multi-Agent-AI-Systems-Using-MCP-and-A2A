"""MAKDO - Multi-Agent Kubernetes DevOps System

A multi-agent system built on AI-6 framework for autonomous Kubernetes cluster
management and DevOps operations.
"""

__version__ = "0.1.0"
__author__ = "Gigi Sayfan"

from .main import main

def cli_main():
    """CLI entry point (used by `uv run makdo`)."""
    return main()

__all__ = ["main", "cli_main"]
