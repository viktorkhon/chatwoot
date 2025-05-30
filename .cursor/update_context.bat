@echo off
echo Cursor AI Context Updater
echo =======================
echo.

REM Create a temporary file to store the session details
set tempFile="%TEMP%\session_details.txt"
set contextFile="%~dp0project_context.md"

REM Get session title
set /p sessionTitle="Enter session title: "
echo.
echo Enter session summary (one item per line)
echo When finished, type 'DONE' on a new line and press Enter
echo.

REM Get summary lines
echo. > %tempFile%
:input_loop
set /p summaryLine=""
if /i "%summaryLine%"=="DONE" goto process_input
echo %summaryLine% >> %tempFile%
goto input_loop

:process_input
echo.
echo Processing your input...

REM Run the Node.js script with the details
node "%~dp0update_context_win.js" "%sessionTitle%" %tempFile%

REM Clean up
if exist %tempFile% del %tempFile%

echo.
echo Context updated successfully!
echo.
pause 