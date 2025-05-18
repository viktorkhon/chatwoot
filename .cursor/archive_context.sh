#!/bin/bash

echo "Running Context Archive Tool..."
node "$(dirname "$0")/archive_context.js"
echo
echo "Press any key to continue..."
read -n 1 