// Windows-specific Context Update Helper Script
// This script is called by update_context.bat with commandline arguments

const fs = require('fs');
const path = require('path');

// Get arguments from command line
const sessionTitle = process.argv[2] || 'Untitled Session';
const summaryFilePath = process.argv[3];

// Get current date in YYYY-MM-DD format
const today = new Date();
const date = today.toISOString().split('T')[0];

// Context file path
const contextFilePath = path.join(__dirname, 'project_context.md');

// Function to update the context file
function updateContextFile(title, summaryText) {
  // Read existing content
  try {
    const data = fs.readFileSync(contextFilePath, 'utf8');
    
    // Find the position after "<!-- New sessions will be added at the top -->" line
    const insertPosition = data.indexOf('<!-- New sessions will be added at the top -->') + 
                          '<!-- New sessions will be added at the top -->'.length;
    
    // Format new session entry
    const newSessionEntry = `\n\n### ${title} - [Date: ${date}]`;
    
    // Format session summary as bullet points
    const summaryPoints = summaryText.split('\n')
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
  } catch (err) {
    console.error('Error updating context file:', err);
  }
}

// Read the summary from the file
try {
  const summaryText = fs.readFileSync(summaryFilePath, 'utf8');
  updateContextFile(sessionTitle, summaryText);
} catch (err) {
  console.error('Error reading summary file:', err);
} 