@echo off
rem Builds Paxon from a fresh clone: the program, the language DLLs, the component package
rem and DebugMonitor. Output goes to Bin\ and Temp\, together with the files Paxon needs at
rem runtime (Paxon.fon, Paxon-EN.pxl, Paxon-FR.pxl).
rem dcc32.exe from Delphi 7 must be on the path, or set DCC32 to its full path.
setlocal
cd /d "%~dp0"
if not defined DCC32 set DCC32=dcc32

for %%d in (Bin Temp Temp\debugmon src\VCL\paxon\build) do (
  if not exist %%d mkdir %%d
)

echo Paxon.exe
pushd src
"%DCC32%" -B -Q Paxon.dpr || (popd & goto error)
popd

for %%l in (ENU FRA) do (
  echo Paxon.%%l
  pushd src\%%l
  "%DCC32%" -B -Q Paxon.dpr || (popd & goto error)
  popd
)
move /y Bin\Paxon.ENU Bin\Paxon-EN.pxl >nul || goto error
move /y Bin\Paxon.FRA Bin\Paxon-FR.pxl >nul || goto error
copy /y src\Font\Paxon.fon Bin\Paxon.fon >nul || goto error

echo PaxonComponents.dpk
pushd src\VCL\paxon
"%DCC32%" -B -Q PaxonComponents.dpk || (popd & goto error)
popd

echo DebugMonitor.exe
pushd DebugMonitor
"%DCC32%" -B -Q DebugMonitor.dpr || (popd & goto error)
popd

echo.
echo Done: Bin\Paxon.exe
exit /b 0

:error
echo.
echo Build failed.
exit /b 1
