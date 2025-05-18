# Cursor AI Context Tracking System

This system helps maintain context between Cursor AI chat sessions by storing project history, current focus, and session summaries in a persistent file.

## How It Works

1. The `project_context.md` file stores your project history and context
2. Cursor AI automatically reads this file at the beginning of each session through the `project-context.mdc` rule
3. After each meaningful session, you update the context file with session details

## Usage

### Starting a New Chat Session

Simply start a new chat with Cursor AI as usual. The AI will automatically read the `project_context.md` file to understand previous work.

### After Completing a Chat Session

1. Run the update script:
   - Windows: Double-click on `update_context.bat`
   - Mac/Linux: Run `node update_context.js` from this directory or use the `update_context.sh` script

2. Enter a title for the session (e.g., "Implemented User Authentication")

3. Enter a summary of what was accomplished during the session
   - Each line will become a bullet point in the context file
   - Press Ctrl+D (or Ctrl+Z on Windows) when finished
   - For the batch script, type 'DONE' on a new line when finished

### Managing Context Size

When your context file grows too large:

1. Run the archive script:
   - Windows: Double-click on `archive_context.bat`
   - Mac/Linux: Run `node archive_context.js` from this directory

2. Follow the prompts to archive older sessions:
   - Choose how many recent sessions to keep
   - Optionally summarize the archived sessions

## Tips for Effective Context Management

1. **Be Specific**: Write clear, specific summaries about what was accomplished
2. **Focus on Key Details**: Include file paths, components modified, and important decisions
3. **Keep Recent Work at Top**: The system automatically adds new sessions at the top
4. **Prune Regularly**: Use the archive tool when the context file grows too large

## Advanced Usage

You can manually edit the `project_context.md` file to:
- Add custom sections for project-specific information
- Update the "Current Focus" section when priorities change
- Restructure the information as your project grows

## Troubleshooting

If Cursor AI's responses indicate it's not fully understanding the context:
1. Make sure the context file is being properly referenced
2. Check if the context file has grown too large (over 100KB may be problematic)
3. Use the archive tool to reduce the context size while preserving important information 