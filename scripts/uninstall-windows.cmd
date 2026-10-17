@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem vim-draft-inbox 1.0.0 - Windows uninstaller

set "VIM_ROOT=%USERPROFILE%\vimfiles"
if not "%~1"=="" set "VIM_ROOT=%~1"

set "PLUGIN_FILE=%VIM_ROOT%\plugin\vim_draft_inbox.vim"
set "HELP_FILE=%VIM_ROOT%\doc\vim-draft-inbox.txt"
set "DOC_DIR=%VIM_ROOT%\doc"

if exist "%PLUGIN_FILE%" (
    del /Q "%PLUGIN_FILE%"
    if errorlevel 1 exit /b 1
    echo Removed: %PLUGIN_FILE%
)

if exist "%HELP_FILE%" (
    del /Q "%HELP_FILE%"
    if errorlevel 1 exit /b 1
    echo Removed: %HELP_FILE%
)

where vim >nul 2>nul
if not errorlevel 1 (
    if exist "%DOC_DIR%" (
        set "DOC_DIR_VIM=%DOC_DIR:\=/%"
        vim -Nu NONE -n -es -c "execute 'helptags ' . fnameescape('%DOC_DIR_VIM%')" -c "qa"
    )
)

echo.
echo vim-draft-inbox uninstallation completed.
exit /b 0
