#!/bin/bash
echo 'Testing GitHub App auth'
gh issue list --repo strawgate/agentic-workflows --limit 1 --json number
echo 'Test completed'
