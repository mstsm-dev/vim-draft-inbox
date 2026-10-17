@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem vim-draft-inbox 1.0.0 - Windows installer
rem Usage:
rem   install-windows.cmd
rem   install-windows.cmd "D:\vimfiles"
rem   install-windows.cmd "D:\vimfiles" --force

set "VIM_ROOT=%USERPROFILE%\vimfiles"
set "FORCE=0"

if not "%~1"=="" (
    if /I "%~1"=="--force" (
        set "FORCE=1"
    ) else (
        set "VIM_ROOT=%~1"
    )
)

if /I "%~2"=="--force" set "FORCE=1"

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PACKAGE_ROOT=%%~fI"

set "SOURCE_PLUGIN=%PACKAGE_ROOT%\plugin\vim_draft_inbox.vim"
set "SOURCE_HELP=%PACKAGE_ROOT%\doc\vim-draft-inbox.txt"

set "PLUGIN_DIR=%VIM_ROOT%\plugin"
set "DOC_DIR=%VIM_ROOT%\doc"

set "TARGET_PLUGIN=%PLUGIN_DIR%\vim_draft_inbox.vim"
set "TARGET_HELP=%DOC_DIR%\vim-draft-inbox.txt"

if not exist "%SOURCE_PLUGIN%" (
    echo ERROR: Plugin file not found:
    echo   %SOURCE_PLUGIN%
    exit /b 1
)

if not exist "%SOURCE_HELP%" (
    echo ERROR: Help file not found:
    echo   %SOURCE_HELP%
    exit /b 1
)

if not exist "%PLUGIN_DIR%" mkdir "%PLUGIN_DIR%"
if errorlevel 1 exit /b 1

if not exist "%DOC_DIR%" mkdir "%DOC_DIR%"
if errorlevel 1 exit /b 1

call :CopyFile "%SOURCE_PLUGIN%" "%TARGET_PLUGIN%"
if errorlevel 1 exit /b 1

call :CopyFile "%SOURCE_HELP%" "%TARGET_HELP%"
if errorlevel 1 exit /b 1

where vim >nul 2>nul
if errorlevel 1 (
    echo.
    echo WARNING: vim.exe was not found in PATH.
    echo Run this in Vim:
    echo   :helptags ~/vimfiles/doc
) else (
    echo.
    echo Generating Vim help tags...
    set "DOC_DIR_VIM=%DOC_DIR:\=/%"
    vim -Nu NONE -n -es -c "execute 'helptags ' . fnameescape('%DOC_DIR_VIM%')" -c "qa"
    if errorlevel 1 (
        echo WARNING: Could not generate help tags automatically.
        echo Run this in Vim:
        echo   :helptags ~/vimfiles/doc
    )
)

echo.
echo vim-draft-inbox 1.0.0 installation completed.
echo Plugin : %TARGET_PLUGIN%
echo Help   : %TARGET_HELP%
echo.
echo Restart Vim, then use:
echo   :help vim-draft-inbox
exit /b 0

:CopyFile
set "SRC=%~1"
set "DST=%~2"

if exist "%DST%" (
    if "%FORCE%"=="0" (
        copy /Y "%DST%" "%DST%.bak" >nul
        if errorlevel 1 exit /b 1
        echo Backup: %DST%.bak
    )
)

copy /Y "%SRC%" "%DST%" >nul
if errorlevel 1 exit /b 1

echo Installed: %DST%
exit /b 0
