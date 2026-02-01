#!/usr/bin/env python3
"""
Tests for PlannerApp workflow_quality_check
"""
import sys
import os
from unittest.mock import patch

# Add root to path
current_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.abspath(os.path.join(current_dir, "../.."))
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

import PlannerApp.workflow_quality_check as wqc


def test_main():
    """Test main function returns 0."""
    with patch("builtins.print"):
        assert wqc.main() == 0
