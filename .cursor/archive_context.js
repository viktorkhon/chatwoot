// Context Archiving Tool
// This script helps manage the size of your project context file
// by moving older entries to an archive section

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const contextFilePath = path.join(__dirname, 'project_context.md');

// Function to create an interactive interface
function createInterface() {
  return readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
}

// Function to archive sessions
function archiveOldSessions() {
  try {
    // Read the context file
    const content = fs.readFileSync(contextFilePath, 'utf8');
    
    // Split the file into lines
    const lines = content.split('\n');
    
    // Find all session entries
    const sessionLines = [];
    let inSessionHistory = false;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      if (line.trim() === '## Session History') {
        inSessionHistory = true;
      } else if (inSessionHistory && line.match(/^## /)) {
        inSessionHistory = false;
      }
      
      if (inSessionHistory && line.match(/^### /)) {
        sessionLines.push({
          index: i,
          title: line.replace(/^### /, '').trim()
        });
      }
    }
    
    if (sessionLines.length <= 3) {
      console.log('Not enough sessions to archive. Need more than 3 sessions.');
      return;
    }
    
    console.log('Found the following sessions:');
    sessionLines.forEach((session, index) => {
      console.log(`${index + 1}. ${session.title}`);
    });
    
    const rl = createInterface();
    
    rl.question('\nHow many recent sessions would you like to keep? (Default: 3) ', (answer) => {
      const keepCount = parseInt(answer) || 3;
      
      if (keepCount >= sessionLines.length) {
        console.log('You chose to keep all sessions. No archiving needed.');
        rl.close();
        return;
      }
      
      const sessionsToArchive = sessionLines.slice(keepCount);
      
      // Add archived sessions section if it doesn't exist
      if (!content.includes('## Archived Sessions')) {
        let updatedContent = content;
        
        // Add archived sessions section before the Notes section or at the end
        const notesIndex = content.indexOf('## Notes');
        if (notesIndex !== -1) {
          updatedContent = 
            content.slice(0, notesIndex) + 
            '## Archived Sessions\n\n' + 
            content.slice(notesIndex);
        } else {
          updatedContent += '\n\n## Archived Sessions\n\n';
        }
        
        fs.writeFileSync(contextFilePath, updatedContent, 'utf8');
      }
      
      // Now process the archive
      processArchive(sessionsToArchive, keepCount, rl);
    });
  } catch (err) {
    console.error('Error reading or parsing context file:', err);
  }
}

// Process the actual archiving
function processArchive(sessionsToArchive, keepCount, rl) {
  try {
    // Read the updated content
    let content = fs.readFileSync(contextFilePath, 'utf8');
    
    rl.question('\nWould you like to summarize the archived sessions? (y/n) ', (answer) => {
      const shouldSummarize = answer.toLowerCase().startsWith('y');
      
      if (shouldSummarize) {
        rl.question('\nEnter a summary title for the archived sessions: ', (title) => {
          const today = new Date();
          const date = today.toISOString().split('T')[0];
          
          // Create a summary entry
          let summary = `### Archived ${sessionsToArchive.length} Sessions - [Date: ${date}]\n`;
          summary += `Sessions archived: ${sessionsToArchive.map(s => s.title.split(' - ')[0]).join(', ')}\n\n`;
          
          // Find the archived sessions section
          const archiveIndex = content.indexOf('## Archived Sessions') + '## Archived Sessions'.length;
          
          // Insert the summary
          content = 
            content.slice(0, archiveIndex) + 
            '\n\n' + summary + 
            content.slice(archiveIndex);
          
          // Now remove the old sessions (starting from the last to avoid index issues)
          const sessionHistory = content.indexOf('## Session History');
          const nextSection = content.indexOf('##', sessionHistory + 15);
          
          // Extract the session history section
          let sessionHistoryContent = content.substring(sessionHistory, nextSection);
          
          // Remove the sessions to archive
          sessionsToArchive.forEach(session => {
            const sessionStart = sessionHistoryContent.indexOf(session.title);
            if (sessionStart !== -1) {
              const sessionEnd = sessionHistoryContent.indexOf('###', sessionStart + session.title.length);
              if (sessionEnd !== -1) {
                sessionHistoryContent = 
                  sessionHistoryContent.substring(0, sessionStart - 4) + // Remove the ### and newlines
                  sessionHistoryContent.substring(sessionEnd - 1); // Keep the newline before next session
              } else {
                // This is the last session, remove till the end
                sessionHistoryContent = sessionHistoryContent.substring(0, sessionStart - 4);
              }
            }
          });
          
          // Replace the session history section
          content = 
            content.substring(0, sessionHistory) + 
            sessionHistoryContent + 
            content.substring(nextSection);
          
          // Write the updated content
          fs.writeFileSync(contextFilePath, content, 'utf8');
          console.log(`\nSuccessfully archived ${sessionsToArchive.length} sessions with a summary.`);
          rl.close();
        });
      } else {
        // TODO: Implement the non-summary archive option
        console.log("Non-summary archiving is not implemented yet. Please choose to summarize.");
        rl.close();
      }
    });
  } catch (err) {
    console.error('Error during archiving:', err);
    if (rl) rl.close();
  }
}

// Main execution
console.log('Context Archiving Tool\n---------------------');
console.log('This tool helps manage the size of your project context file by archiving older sessions.\n');

archiveOldSessions(); 