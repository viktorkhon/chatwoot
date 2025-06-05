@echo off
echo.
echo ==============================================
echo  QUICK URL UPDATER - No Restart Required!
echo ==============================================
echo.
echo Paste your new Cloudflare tunnel URL below:
echo (Example: https://abc-123.trycloudflare.com)
echo.
set /p NEW_URL="Enter URL: "

if "%NEW_URL%"=="" (
    echo Error: No URL provided
    pause
    exit /b 1
)

echo.
echo Updating FRONTEND_URL to: %NEW_URL%
echo.

powershell -ExecutionPolicy Bypass -File "update_tunnel_url.ps1" -NewUrl "%NEW_URL%"

echo.
echo Done! Press any key to close...
pause >nul 