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
rem -GD writes src\Paxon.drc (the resourcestring IDs) and a detailed Bin\Paxon.map
if exist src\Paxon.drc del src\Paxon.drc
pushd src
"%DCC32%" -B -Q -GD Paxon.dpr || (popd & goto error)
popd
if exist Bin\Paxon.map del Bin\Paxon.map

rem The language DLLs replace resourcestrings by ID: their Paxon_DRC.rc must match Paxon.exe
for %%l in (ENU FRA) do (
  call :checkdrc %%l || goto error
)

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

rem Compares the #define lines (name and ID) of src\%1\Paxon_DRC.rc with src\Paxon.drc
:checkdrc
powershell -NoProfile -Command "$e = @(Select-String -LiteralPath 'src\Paxon.drc' -Pattern '^#define\s' -CaseSensitive | ForEach-Object { $_.Line.Trim() }); $l = @(Select-String -LiteralPath 'src\%1\Paxon_DRC.rc' -Pattern '^#define\s' -CaseSensitive | ForEach-Object { $_.Line.Trim() }); if ($e.Count -eq 0 -or $e.Count -ne $l.Count -or (Compare-Object $e $l -CaseSensitive)) { exit 1 }"
if errorlevel 1 (
  echo.
  echo src\%1\Paxon_DRC.rc does not match the resourcestrings of Paxon.exe ^(src\Paxon.drc^).
  echo Regenerate it from src\Paxon.drc: names and IDs of all #define lines must be identical.
  exit /b 1
)
exit /b 0
