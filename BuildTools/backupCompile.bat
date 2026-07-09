
@echo off
if "%1"=="" (
    call :GET_THIS_DIR
    NESASM3 %PROJECT_NAME%.asm
    pause
    goto :EOF

    :GET_THIS_DIR
    pushd %~dp0
    for %%A in ("%CD%") do set "PROJECT_NAME=%%~nxA"
    popd
    goto :EOF
) else (
    NESASM3 %1
)
pause

