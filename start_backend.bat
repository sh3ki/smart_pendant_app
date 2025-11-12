@echo off
REM Quick script to start backend with Arduino IP

SET /P ARDUINO_IP="Enter Arduino IP address (e.g., 192.168.224.100): "

echo.
echo ========================================
echo Starting Backend Server
echo ========================================
echo Arduino IP: %ARDUINO_IP%
echo Backend URL: http://192.168.224.11:3000
echo ========================================
echo.

cd backend
set ARDUINO_IP=%ARDUINO_IP%
node server.js
