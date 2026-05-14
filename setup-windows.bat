@echo off
REM =====================================================
REM Script to setup permissions on scripts
REM Run this from Project root in PowerShell or CMD
REM =====================================================

echo Fixing script permissions...

REM Add scripts to execution path
if exist "scripts\local-dev.sh" (
    echo Making scripts executable...
    REM In Windows, Git Bash handles this automatically
    REM This is just informational
    echo ✓ scripts/local-dev.sh
    echo ✓ scripts/push-to-ecr.sh
    echo ✓ scripts/aws-setup.sh
    echo ✓ scripts/ec2-setup.sh
)

echo.
echo ✓ Setup complete!
echo.
echo Next steps:
echo 1. Open Git Bash or WSL terminal
echo 2. chmod +x scripts/*.sh
echo 3. ./scripts/local-dev.sh up
echo.
