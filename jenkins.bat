@echo off

SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

virtualenv -p python3.6 .\python3_virtual_env
CALL .\python3_virtual_env\Scripts\activate

cd PChome_Price_Tracker

pip install -r requirements.txt

CALL :runTest
CALL :postProcessing

deactivate
EXIT 0

:runTest
SET ROUND=0
robot -F robot -d ./out/%BUILD_NUMBER% -o output-0.xml -l NONE -r NONE -P ./"keywords" -L TRACE:INFO "PChome Price Tracker.robot"
if %ERRORLEVEL% neq 0 (
    :retry
    TIME /T
    SET /A ROUND+=1
    robot -F robot -d ./out/%BUILD_NUMBER% -o output-!ROUND!.xml -l NONE -r NONE -P ./"keywords" -L TRACE:INFO "PChome Price Tracker.robot"
    if !ERRORLEVEL! NEQ 0 if !ROUND! LSS %FAIL_RETRY% GOTO retry
)
TIME /T
GOTO :EOF

:postProcessing
for /F "delims=" %%F in ('dir /B /ON /A-D .\out\%BUILD_NUMBER%\output-*.xml') do (
    SET "FILES=!FILES! .\out\%BUILD_NUMBER%\%%F"
)
echo =================================Test  Result=================================
rebot -d ./out/%BUILD_NUMBER%/result -o output.xml -l log.html -r report.html -L TRACE:INFO --merge %FILES%
echo ================================Merged  Output================================
rebot -d ./out/%BUILD_NUMBER% -l log.html -r report.html -L TRACE:INFO --name "PChome Price Tracker" %FILES%
DEL .\out\%BUILD_NUMBER%\output-*.xml
GOTO :EOF