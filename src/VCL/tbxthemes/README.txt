TBX themes for Paxon
====================

This folder contains the parts of TBX 2.5 (https://github.com/plashenkov/TBX)
that Paxon needs to draw its bars, menus and status bar:

  TBXThemes.pas      Theme interface and theme management
  TBXUtils.pas       Drawing helpers, shadows
  TBXUxThemes.pas    Access to uxtheme.dll
  TBXConsts.pas      Color constants
  TBXOfficeXPTheme.pas  Theme "OfficeXP", the only one Paxon draws with
  TBXStatusBars.pas  Status bar
  TBXCore.pas        Extract from TBX.pas: current theme (OfficeXP),
                     font settings, drawing helpers
  TBX.inc            TBX switches

License: MIT, see LICENSE and the file headers.

Changes compared to TBX 2.5 (2026, for Paxon):

  - The units use VCL\paxon\src\ToolbarHelpU.pas for small drawing and system
    helpers (DrawRotatedText, DrawHalftoneInvertRect, ProcessPaintMessages,
    IsWindowsXP, GetSystemParametersInfoBool, GetTextWidth, Min, Max,
    ToolbarFont and DT_HIDEPREFIX) and the unit TBXCore instead of TBX.
    The code paths for external image lists are removed.
  - TBXVer.inc is the version include of these units.
  - TBXCore.pas is newly assembled from TBX.pas.
  - Only the OfficeXP theme remains; Default, Aluminum, Roma and Whidbey
    (with rmkThemes.pas) are removed.

The bars and menus themselves are in VCL\paxon\src\ToolbarU.pas and are
Paxon's own code.
