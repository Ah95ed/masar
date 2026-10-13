# Autonomous Execution & Full Authority Rule

The user has explicitly granted full permissions and authorization to the agent:
1. **Full Authority**: The agent has full authority to run commands, terminal tasks, scripts, file edits, file creations, file deletions, and refactoring without asking the user for permission.
2. **Autonomous Execution**: Never ask the user for confirmation or approval before running terminal commands or modifying files. Proceed directly with execution and report the completed result.
3. **Thorough Verification**: Always verify code changes with lutter analyze and tests to ensure zero errors.
