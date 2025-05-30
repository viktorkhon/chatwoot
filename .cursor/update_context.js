// Update Context Helper Script
// Run this script to add a new session entry to the project context file

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const contextFilePath = path.join(__dirname, 'project_context.md');

// Get current date in YYYY-MM-DD format
const today = new Date();
const date = today.toISOString().split('T')[0];

// Function to update the context file
function updateContextFile(sessionTitle, sessionSummary) {
  // Read existing content
  try {
    const data = fs.readFileSync(contextFilePath, 'utf8');
    
    // Find the position after "<!-- New sessions will be added at the top -->" line
    const insertPosition = data.indexOf('<!-- New sessions will be added at the top -->') + 
                          '<!-- New sessions will be added at the top -->'.length;
    
    // Format new session entry
    const newSessionEntry = `\n\n### ${sessionTitle} - [Date: ${date}]`;
    
    // Format session summary as bullet points
    const summaryPoints = sessionSummary.split('\n')
      .filter(line => line.trim() !== '')
      .map(line => `- ${line.trim()}`);
    
    const formattedSummary = '\n' + summaryPoints.join('\n');
    
    // Insert new content after the comment
    const updatedContent = 
      data.slice(0, insertPosition) + 
      newSessionEntry + 
      formattedSummary + 
      data.slice(insertPosition);

    // Write updated content back to file
    fs.writeFileSync(contextFilePath, updatedContent, 'utf8');
    console.log('Project context updated successfully!');
    return true;
  } catch (err) {
    console.error('Error updating context file:', err);
    return false;
  }
}

// Check if running with command-line arguments (for shell script integration)
if (process.argv.length >= 4) {
  const sessionTitle = process.argv[2];
  const summaryFilePath = process.argv[3];
  
  try {
    const summaryText = fs.readFileSync(summaryFilePath, 'utf8');
    updateContextFile(sessionTitle, summaryText);
    process.exit(0);
  } catch (err) {
    console.error('Error reading summary file:', err);
    process.exit(1);
  }
} else {
  // Interactive mode
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  console.log('Update Project Context\n---------------------');
  console.log('This will add a new session entry to your project context file.\n');

  rl.question('Session title: ', (title) => {
    console.log('\nEnter session summary (multiple lines, press Ctrl+D when finished):');
    
    let summaryLines = [];
    
    rl.on('line', (line) => {
      summaryLines.push(line);
    });
    
    rl.on('close', () => {
      updateContextFile(title, summaryLines.join('\n'));
    });
  });
} 