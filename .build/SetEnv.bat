@ECHO OFF

:: Reset ERRORLEVEL
VERIFY OTHER 2>nul



:: -------------------------------------------------------------------
:: Set environment variables
:: -------------------------------------------------------------------
CALL :SetVersionsEnvHelper 2>nul

CALL :SetGitHomePathHelper > nul 2>&1
IF ERRORLEVEL 1 GOTO ERROR_GIT
ECHO SET GitHomePath=%GitHomePath%

CALL :SetNodeJsHomePathHelper 2>nul
IF ERRORLEVEL 1 GOTO ERROR_NODEJS
ECHO SET NodeJsHomePath=%NodeJsHomePath%

ECHO.

CALL :SetLocalEnvHelper 2>nul

IF EXIST "%NodeJsHomePath%nodevars.bat" (
    :: Regular  installation
    CALL "%NodeJsHomePath%nodevars.bat"
) ELSE (
    :: Probably nvm-windows
    IF "%NVM_HOME%" NEQ "" (
        SET "PATH=%NVM_HOME%;%NodeJsHomePath%;%PATH%"
    ) ELSE (
        SET "PATH=%NodeJsHomePath%;%PATH%"
    )
)
SET "PATH=%CD%\node_modules\.bin;%GitHomePath%bin;%MSDeployHomePath%;%PATH%"
GOTO END



:SetLocalEnvHelper
IF EXIST .env (
    FOR /F "eol=# tokens=1* delims==" %%i IN (.env) DO (
        SET "%%i=%%j"
        ECHO SET %%i=%%j
    )
    ECHO.
)
EXIT /B 0



:SetVersionsEnvHelper
IF EXIST build\versions.env (
    FOR /F "eol=# tokens=1* delims==" %%i IN (build\versions.env) DO (
        SET "%%i=%%j"
        ECHO SET %%i=%%j
    )
    ECHO.
)
EXIT /B 0



:SetNodeJsHomePathHelper
SET NodeJsHomePath=
IF "%NVM_SYMLINK%" NEQ "" (
    SET "NodeJsHomePath=%NVM_SYMLINK%\"
) ELSE (
    FOR /F "tokens=1* delims=" %%i IN ('where.exe node.exe') DO SET "NodeJsHomePath=%%~dpi"
)
IF EXIST "%NodeJsHomePath%\node.exe" (
    EXIT /B 0
)

SET NodeJsHomePath=
FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_CURRENT_USER\Software\Node.js /V InstallPath') DO (
    IF "%%i"=="InstallPath" (
        SET "NodeJsHomePath=%%k"
    )
)
IF "%NodeJsHomePath%"=="" (
    FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Node.js /V InstallPath') DO (
        IF "%%i"=="InstallPath" (
            SET "NodeJsHomePath=%%k"
        )
    )
)
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    IF "%NodeJsHomePath%"=="" (
        FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_CURRENT_USER\Software\Wow6432Node\Node.js /V InstallPath') DO (
            IF "%%i"=="InstallPath" (
                SET "NodeJsHomePath=%%k"
            )
        )
    )
    IF "%NodeJsHomePath%"=="" (
        FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Node.js /V InstallPath') DO (
            IF "%%i"=="InstallPath" (
                SET "NodeJsHomePath=%%k"
            )
        )
    )
)
IF "%NodeJsHomePath%"=="" EXIT /B 1
EXIT /B 0



:SetGitHomePathHelper
SET GitHomePath=
FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /V InstallLocation') DO (
    IF "%%i"=="InstallLocation" (
        SET "GitHomePath=%%k"
    )
)
IF "%GitHomePath%"=="" (
    FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /V InstallLocation') DO (
        IF "%%i"=="InstallLocation" (
            SET "GitHomePath=%%k"
        )
    )
)
IF "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    IF "%GitHomePath%"=="" (
        FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_CURRENT_USER\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /V InstallLocation') DO (
            IF "%%i"=="InstallLocation" (
                SET "GitHomePath=%%k"
            )
        )
    )
    IF "%GitHomePath%"=="" (
        FOR /F "tokens=1,2*" %%i IN ('REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1 /V InstallLocation') DO (
            IF "%%i"=="InstallLocation" (
                SET "GitHomePath=%%k"
            )
        )
    )
)
IF "%GitHomePath%"=="" EXIT /B 1
EXIT /B 0



:ERROR_EXT
ECHO [31mCould not activate command extensions[0m 1>&2
GOTO END_ERROR

:ERROR_NODEJS
ECHO [31mCould not find node.js[0m
GOTO END_ERROR

:ERROR_GIT
ECHO [31mCould not find Git[0m
GOTO END_ERROR

:END_ERROR
EXIT /B 1

:END
