@echo off
nimony n src/main.nim -o:bin/nimony-lsp.new.exe
if errorlevel 1 exit /b 1
taskkill /f /im nimony-lsp.exe >nul 2>&1
move /y bin\nimony-lsp.new.exe bin\nimony-lsp.exe >nul
