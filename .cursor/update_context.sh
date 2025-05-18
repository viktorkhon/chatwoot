#!/bin/bash

echo "Cursor AI Context Updater"
echo "======================="
echo

# Get session title
read -p "Enter session title: " SESSION_TITLE
echo
echo "Enter session summary (one item per line)"
echo "When finished, press Ctrl+D on a new line"
echo

# Get summary lines
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE"

echo
echo "Processing your input..."

# Run the Node.js script
node "$(dirname "$0")/update_context.js" "$SESSION_TITLE" "$TEMP_FILE"

# Clean up
rm -f "$TEMP_FILE"

echo
echo "Context updated successfully!"
echo 