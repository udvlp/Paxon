@echo off
rem Compiles the resource scripts (*.rc) of the main program and the language DLLs.
rem brcc32.exe from Delphi 7 must be on the path.
cd /d "%~dp0"
for %%r in (Resources-Global Resources-Local winxp) do brcc32 -fo %%r.res %%r.rc
for %%l in (ENU FRA) do (
  pushd %%l
  for %%r in (Resources-Global Resources-Local Paxon_DRC) do brcc32 -fo %%r.res %%r.rc
  popd
)
