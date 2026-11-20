@echo off
nimony c -o:bin/nimony-lsp.new.exe src/main.nim
if errorlevel 1 exit /b 1
taskkill /f /im nimony-lsp.exe >nul 2>&1
move /y bin\nimony-lsp.new.exe bin\nimony-lsp.exe >nul
