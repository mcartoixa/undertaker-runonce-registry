@ECHO OFF

:: Reset ERRORLEVEL
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
IF ERRORLEVEL 1 GOTO ERROR_EXT

SET NO_PAUSE=0
SET TARGET=build
SET VERBOSITY=notice
GOTO ARGS

:SHOW_USAGE
ECHO.
ECHO Usage: "build [clean | compile |  test | analyze | package | prepare | build | rebuild | release] [/log] [/NoPause] [/?]"
ECHO.
ECHO.                /NoPause  - Does not pause after completion
ECHO.                /log      - Creates an extensive log file
ECHO.                /?        - Gets the usage for this script
IF "%_ERROR%"=="1" GOTO END_ERROR
GOTO END



:BUILD
:: -------------------------------------------------------------------
:: Builds the project
:: -------------------------------------------------------------------
ECHO.
CALL npm.cmd install --loglevel %VERBOSITY%
IF ERRORLEVEL 1 GOTO END_ERROR
ECHO.
CALL npm.cmd run-script "build:%TARGET%" --loglevel %VERBOSITY%%VERBOSITY_%
IF ERRORLEVEL 1 GOTO END_ERROR
GOTO END



:ARGS
:: -------------------------------------------------------------------
:: Parse command line argument values
:: Note: Currently, last one on the command line wins (ex: rebuild clean == clean)
:: -------------------------------------------------------------------
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (
    "C:\Windows\Sysnative\cmd.exe" /C "%0 %*"

    IF ERRORLEVEL 1 EXIT /B 1
    EXIT /B 0
)
::IF NOT "x%~5"=="x" GOTO ERROR_USAGE

:ARGS_PARSE
IF /I "%~1"=="clean"                SET TARGET=clean& RMDIR /S /Q .tmp& RMDIR /S /Q node_modules& RMDIR /S /Q tmp& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="analyze"              SET TARGET=analyze& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="compile"              SET TARGET=compile& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="test"                 SET TARGET=test& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="package"              SET TARGET=package& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="prepare"              SET TARGET=prepare& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="rebuild"              SET TARGET=rebuild& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="build"                SET TARGET=build& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="release"              SET TARGET=release& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="/log"                 SET VERBOSITY=verbose& SET VERBOSITY_= -- -LLLL& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="/NoPause"             SET NO_PAUSE=1& SHIFT & GOTO ARGS_PARSE
IF /I "%~1"=="/?"   GOTO SHOW_USAGE
IF    "%~1" EQU ""  GOTO ARGS_DONE
ECHO [31mUnknown command-line switch[0m %~1
GOTO ERROR_USAGE

:ARGS_DONE



:SETENV
:: -------------------------------------------------------------------
:: Set environment variables
:: -------------------------------------------------------------------
CALL .build\SetEnv.bat
IF ERRORLEVEL 1 GOTO END_ERROR
ECHO.
GOTO BUILD



:: -------------------------------------------------------------------
:: Errors
:: -------------------------------------------------------------------
:ERROR_EXT
ECHO [31mCould not activate command extensions[0m
GOTO END_ERROR

:ERROR_USAGE
SET _ERROR=1
GOTO SHOW_USAGE



:: -------------------------------------------------------------------
:: End
:: -------------------------------------------------------------------
:END_ERROR
ECHO.
ECHO [41m                                                                                [0m
ECHO [41;1mThe build failed                                                                [0m
ECHO [41m                                                                                [0m

:END
@IF NOT "%NO_PAUSE%"=="1" PAUSE
ENDLOCAL
