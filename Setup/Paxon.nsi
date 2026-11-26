;------------------------------------------------------------------------------
; Paxon NSIS Script
;------------------------------------------------------------------------------

; All paths are relative to the folder of this script (Setup\, next to src\ and Bin\; makensis
; changes to it): ..\Bin\Paxon.exe, ..\src\Sound\...

; Version of ..\Bin\Paxon.exe at compile time (defines PaxonVer_1 to PaxonVer_4)
!getdllversion "..\Bin\Paxon.exe" PaxonVer_
!define VersionMajor ${PaxonVer_1}
!define VersionMinor ${PaxonVer_2}
!define VersionBuild ${PaxonVer_4}
!define Version "${PaxonVer_1}.${PaxonVer_2}.${PaxonVer_4}"

Name "Paxon"

!include "${NSISDIR}\Contrib\Modern UI\System.nsh"

; Version information of the installer itself, taken from Paxon.exe
VIProductVersion "${PaxonVer_1}.${PaxonVer_2}.${PaxonVer_3}.${PaxonVer_4}"
VIFileVersion "${PaxonVer_1}.${PaxonVer_2}.${PaxonVer_3}.${PaxonVer_4}"
VIAddVersionKey /LANG=0 "ProductName" "Paxon Packet Radio Terminal"
VIAddVersionKey /LANG=0 "ProductVersion" "${PaxonVer_1}.${PaxonVer_2}.${PaxonVer_3}"
VIAddVersionKey /LANG=0 "FileDescription" "Paxon Setup"
VIAddVersionKey /LANG=0 "FileVersion" "${PaxonVer_1}.${PaxonVer_2}.${PaxonVer_3}.${PaxonVer_4}"
VIAddVersionKey /LANG=0 "CompanyName" "Ulf Haueisen, Frankfurt am Main, Germany"
VIAddVersionKey /LANG=0 "LegalCopyright" "1996-2026 Ulf Haueisen, Frankfurt, Germany. MIT License."


;------------------------------------------------------------------------------
; Configuration
;------------------------------------------------------------------------------

CRCCheck on

; Writes to Program Files and HKLM; say so explicitly instead of relying on the
; installer detection of Windows
RequestExecutionLevel admin

!define MUI_WELCOMEPAGE
!define MUI_LICENSEPAGE
!define MUI_DIRECTORYPAGE
!define MUI_STARTMENUPAGE
!define MUI_FINISHPAGE
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
; Start Paxon via Explorer, i.e. as the logged-on user without elevation (an elevated
; Paxon would use the admin's settings and could not receive drag and drop)
!define MUI_FINISHPAGE_RUN ""
!define MUI_FINISHPAGE_RUN_FUNCTION RunPaxon
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_ABORTWARNING

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\box-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\box-uninstall.ico"

!define MUI_WELCOMEFINISHPAGE_BITMAP "setup.bmp"

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "setup-header.bmp"
!define MUI_HEADERIMAGE_RIGHT

!define MUI_UNCUSTOMPAGECOMMANDS
!define MUI_UNINSTALLER
!define MUI_UNCONFIRMPAGE

!define MUI_CUSTOMFUNCTION_GUIINIT GUIInit
!define MUI_CUSTOMFUNCTION_UNGUIINIT un.GUIInit

!insertmacro MUI_RESERVEFILE_LANGDLL
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
ReserveFile "install.ini"
ReserveFile "uninstall.ini"

Caption "$(CAPTION)"
BrandingText "$(BRANDINGTEXT)"

OutFile "..\Bin\SetupPaxon${VersionBuild}.exe"
InstallDir "$PROGRAMFILES\Paxon"
XPStyle on


;------------------------------------------------------------------------------
; Variables
;------------------------------------------------------------------------------

Var STARTMENU_FOLDER


;------------------------------------------------------------------------------
; Installer Pages
;------------------------------------------------------------------------------

!define MUI_PAGE_CUSTOMFUNCTION_SHOW WelcomeShow
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_LICENSE "$(LICENSE)"

!insertmacro MUI_PAGE_DIRECTORY

; The page suggests the folder of the previous installation; the uninstaller reads it from there
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "SetupStartMenu"
!insertmacro MUI_PAGE_STARTMENU "Application" $STARTMENU_FOLDER

Page custom InstallOptions "" "$(IOTITLE1)"

!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_PAGE_FINISH


;------------------------------------------------------------------------------
; Uninstaller Pages
;------------------------------------------------------------------------------

!insertmacro MUI_UNPAGE_CONFIRM

UninstPage custom un.UninstallOptions "" "$(un.IOTITLE1)"

!insertmacro MUI_UNPAGE_INSTFILES


;------------------------------------------------------------------------------
; Language Strings
;------------------------------------------------------------------------------

!include /CHARSET=CP1252 "lang-english.nsh"
!include /CHARSET=CP1252 "lang-german.nsh"
!include /CHARSET=CP1252 "lang-french.nsh"


;------------------------------------------------------------------------------
; Macros
;------------------------------------------------------------------------------

!macro ApplicationData RESULT
	ReadRegStr ${RESULT} HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" "AppData"
	StrCmp ${RESULT} "" 0 AppDataOk
	StrCpy ${RESULT} "$WINDIR\Anwendungsdaten"
	IfFileExists ${RESULT} AppDataOk
	StrCpy ${RESULT} "$WINDIR\Application Data"
	IfFileExists ${RESULT} AppDataOk
	StrCpy ${RESULT} "$WINDIR"
	AppDataOk:
!macroend


!macro CreateFileAssociation EXTENSION INTERNALNAME DESCRIPTION
	Push $R0
	Push $R1
	ClearErrors
	ReadRegStr $R0 HKCR "${EXTENSION}" ""
	; Back up an existing association of another program; it is restored on
	; uninstall. Do not back up our own entries (Paxon.*).
	StrCmp $R0 "" +4
	StrCpy $R1 $R0 6
	StrCmp $R1 "Paxon." +2
	WriteRegStr HKCR "${EXTENSION}" "Paxon.Backup" $R0
	WriteRegStr HKCR "${EXTENSION}" "" "${INTERNALNAME}"
	WriteRegStr HKCR "${INTERNALNAME}" "" "${DESCRIPTION}"
	WriteRegStr HKCR "${INTERNALNAME}" "NoOpen" ""
	WriteRegStr HKCR "${INTERNALNAME}\DefaultIcon" "" "$INSTDIR\Paxon.exe,1"
	Pop $R1
	Pop $R0
!macroend


!macro DeleteFileAssociation EXTENSION INTERNALNAME
	; Only change the association if it still points to Paxon; then restore the backed-up
	; association or, if there is none, remove the entry
	Push $R0
	Push $R1
	; Before NSIS 3.06, DeleteRegKey /ifempty only checks subkeys, not values.
	; So use it only in the branch without a backup, never after restoring.
	ReadRegStr $R0 HKCR "${EXTENSION}" ""
	StrCmp $R0 "${INTERNALNAME}" 0 +9
	ReadRegStr $R1 HKCR "${EXTENSION}" "Paxon.Backup"
	StrCmp $R1 "" 0 +4
	; Points to Paxon, no backup: remove the entry
	DeleteRegValue HKCR "${EXTENSION}" ""
	DeleteRegKey /ifempty HKCR "${EXTENSION}"
	Goto +5
	; Points to Paxon, backup present: restore it
	WriteRegStr HKCR "${EXTENSION}" "" $R1
	DeleteRegValue HKCR "${EXTENSION}" "Paxon.Backup"
	Goto +2
	; Now belongs to another program: only remove our own backup
	DeleteRegValue HKCR "${EXTENSION}" "Paxon.Backup"
	DeleteRegKey HKCR "${INTERNALNAME}"
	Pop $R1
	Pop $R0
!macroend


;------------------------------------------------------------------------------
; Installer Sections
;------------------------------------------------------------------------------

Section "Paxon"

	!insertmacro ApplicationData $R4

	AddSize 2560

	SetShellVarContext "all"

	; Delete old files

	Delete "$INSTDIR\unins000.dat"
	Delete "$INSTDIR\unins000.exe"
	Delete "$INSTDIR\unins001.dat"
	Delete "$INSTDIR\unins001.exe"
	Delete "$INSTDIR\unins002.dat"
	Delete "$INSTDIR\unins002.exe"
	Delete "$INSTDIR\Paxon-F.dll"
	Delete "$INSTDIR\Sound\NoSound.pxs"
	Delete "$INSTDIR\Sound\Default.pxs"
	Delete "$INSTDIR\Sound\Beta6.pxs"
	Delete "$INSTDIR\Sound\KeineKlänge.pxs"
	Delete "$INSTDIR\Sound\Paxon Dateiübertragung (Erfolg).wav"
	Delete "$INSTDIR\Sound\Paxon Getrennt.wav"
	Delete "$INSTDIR\Sound\Paxon Kanalwechsel.wav"
	Delete "$INSTDIR\Sound\Paxon PGP Signatur gültig.wav"
	Delete "$INSTDIR\Sound\Paxon Ring.wav"
	Delete "$INSTDIR\Sound\Paxon Verbindung (ankommend).wav"
	Delete "$INSTDIR\Sound\Paxon Verbindung (ausgehend).wav"
	Delete "$INSTDIR\Sound\Paxon Zeile empfangen (aktiv).wav"
	Delete "$INSTDIR\Sound\Paxon Zeile empfangen (inaktiv).wav"

	RmDir /r "$R4\Ulf Haueisen\Paxon\Libraries"

	; Delete old registry entries

	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\paxon_is0"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\paxon_is1"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\paxon_is2"
	DeleteRegValue HKCU "Software\Ulf Haueisen\Paxon" "Erste Schritte"
	DeleteRegValue HKCU "Software\Ulf Haueisen\Paxon" "Spruch"
	DeleteRegValue HKCU "Software\Ulf Haueisen\Paxon" "Splash"
	DeleteRegKey HKCU "Software\Ulf Haueisen\Paxon\Fenster"

	; Copy new files

	SetOutPath "$INSTDIR"

	File "..\Bin\Paxon.exe"
	File "..\Bin\Paxon.fon"
	File "..\Bin\Paxon-EN.pxl"
	File "..\Bin\Paxon-FR.pxl"

	SetOutPath "$INSTDIR\Sound"

	File "..\src\Sound\Silence.pxs"
	File "..\src\Sound\Default Wave.pxs"
	File "..\src\Sound\Default PC-Speaker.pxs"

	SetOutPath "$INSTDIR\Sound\Default"

	File "..\src\Sound\Default\Paxon File Transfer Complete.wav"
	File "..\src\Sound\Default\Paxon Disconnected.wav"
	File "..\src\Sound\Default\Paxon Channel Switch.wav"
	File "..\src\Sound\Default\Paxon PGP Signature Valid.wav"
	File "..\src\Sound\Default\Paxon Ring.wav"
	File "..\src\Sound\Default\Paxon Connected (incoming).wav"
	File "..\src\Sound\Default\Paxon Connected (outgoing).wav"
	File "..\src\Sound\Default\Paxon Line Received (active).wav"
	File "..\src\Sound\Default\Paxon Line Received (inactive).wav"

	; Registry

	WriteRegStr HKCU "Software\Ulf Haueisen\Paxon" "ForceDatabaseCheck" "1"

	; Before 3.0 the key was called Klaenge; Paxon copies it to Sounds on first start
	ClearErrors
	ReadRegDWord $R0 HKCU "Software\Ulf Haueisen\Paxon\Klaenge\00" "Signal"
	IfErrors 0 NoDefaultSounds
	ClearErrors
	ReadRegDWord $R0 HKCU "Software\Ulf Haueisen\Paxon\Sounds\00" "Signal"
	IfErrors 0 NoDefaultSounds
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\01" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\01" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Connected (outgoing).wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\02" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\02" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Connected (incoming).wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\04" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\04" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Disconnected.wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\05" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\05" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Disconnected.wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\06" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\06" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Ring.wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\07" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\07" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Line Received (active).wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\08" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\08" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Line Received (inactive).wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\11" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\11" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon File Transfer Complete.wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\14" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\14" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon PGP Signature Valid.wav"
		WriteRegDWord HKCU "Software\Ulf Haueisen\Paxon\Sounds\17" "Signal" 3
		WriteRegStr HKCU "Software\Ulf Haueisen\Paxon\Sounds\17" "SignalWavFile" "$INSTDIR\Sound\Default\Paxon Channel Switch.wav"
	NoDefaultSounds:

	; Start menu

	SetOutPath "$INSTDIR"

	; On an update to another folder (or without shortcuts: ">folder"), remove the old shortcut
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupStartMenu"
	StrCmp $R0 "" OldStartMenuDone
	StrCmp $R0 $STARTMENU_FOLDER OldStartMenuDone
		Delete "$SMPROGRAMS\$R0\Paxon.lnk"
		RMDir "$SMPROGRAMS\$R0"
	OldStartMenuDone:

	; Also written when no shortcuts are created, so that the page remembers this choice
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupStartMenu" "$STARTMENU_FOLDER"
	!insertmacro MUI_STARTMENU_WRITE_BEGIN "Application"
	CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
	CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Paxon.lnk" "$INSTDIR\Paxon.exe"
	!insertmacro MUI_STARTMENU_WRITE_END

	; Desktop Icon

	!insertmacro MUI_INSTALLOPTIONS_READ $R0 "install.ini" "Field 2" "State"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupDesktopIcon" $R0
	StrCmp $R0 "1" "" NoDesktopIcon
	CreateShortCut "$DESKTOP\Paxon.lnk" "$INSTDIR\Paxon.exe"
	Goto DesktopIconDone
	NoDesktopIcon:
	; deselected on an update: remove the shortcut of the previous installation
	Delete "$DESKTOP\Paxon.lnk"
	DesktopIconDone:

	; Quick Launch has no effect since Windows 7: no longer offered, remove the shortcut
	; of older installations

	Delete "$R4\Microsoft\Internet Explorer\Quick Launch\Paxon.lnk"
	DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupQuicklaunchIcon"

	; Register Filetypes

	!insertmacro MUI_INSTALLOPTIONS_READ $R0 "install.ini" "Field 3" "State"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupRegisterFiletypes" $R0
	StrCmp $R0 "1" "" NoFiletypes
		!insertmacro CreateFileAssociation ".pxd" "Paxon.Database" "Paxon Database"
		!insertmacro CreateFileAssociation ".pxf" "Paxon.IncompleteFile" "Paxon Incomplete File"
		!insertmacro CreateFileAssociation ".pxi" "Paxon.IndexFile" "Paxon Index File"
		!insertmacro CreateFileAssociation ".pxl" "Paxon.LanguageResource" "Paxon Language Resource"
		!insertmacro CreateFileAssociation ".pxn" "Paxon.TextBuffer" "Paxon Text Buffer"
		!insertmacro CreateFileAssociation ".pxs" "Paxon.SoundScheme" "Paxon Sound Scheme"
		;SendMessage ${HWND_BROADCAST} ${WM_SETTINGCHANGE} 0x002A 0 /TIMEOUT=5000
	NoFiletypes:

	; Uninstaller

	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "Comments" "Paxon Packet Radio Terminal"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "DisplayIcon" "$INSTDIR\Paxon.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "DisplayName" "Paxon ${VersionMajor}.${VersionMinor}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "DisplayVersion" "${VersionMajor}.${VersionMinor}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupLanguage" "$LANGUAGE"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupPath" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "Publisher" "Ulf Haueisen"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "URLInfoAbout" "mailto:ulf@paxon.app"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "URLUpdateInfo" "https://www.paxon.app/"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "UninstallString" "$INSTDIR\uninstall.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "Version" "${VersionMajor}.${VersionMinor}"

	WriteUninstaller "$INSTDIR\Uninstall.exe"

	; ExecWait '"$INSTDIR\Paxon.exe" /regserver'

SectionEnd


;------------------------------------------------------------------------------
; Installer Functions
;------------------------------------------------------------------------------

Function .onInit

	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "install.ini"

	!define MUI_LANGDLL_WINDOWTITLE "Paxon ${VersionMajor}.${VersionMinor}.${VersionBuild} Setup"
	!define MUI_LANGDLL_INFO "Please select a language.$\r$\nBitte wählen Sie eine Sprache.$\r$\nSélectionnez la langue, s'il vous plait."
	!define MUI_LANGDLL_ALWAYSSHOW

	!insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd


Function GUIInit

	Push $R0

	ClearErrors
	UserInfo::GetAccountType
	IfErrors GroupOk
	Pop $R0
	StrCmp $R0 "Admin" GroupOk
	StrCmp $R0 "Power" GroupOk
	StrCmp $R0 "" GroupOk
	MessageBox MB_OK|MB_ICONEXCLAMATION $(MUSTBEADMIN)
	Abort
	GroupOk:

	PaxonTest:
	FindWindow $R0 "TApplication" "Paxon"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "TApplication" "Paxon Terminal"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "THauptfenster" "Paxon"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "THauptfenster" "Paxon Terminal"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "TMainWindow" "Paxon"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "TMainWindow" "Paxon Terminal"
	StrCmp $R0 "0" 0 PaxonFound
	goto PaxonNotFound
	PaxonFound:
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION $(CLOSEPAXON) IDOK PaxonTest
	Abort
	PaxonNotFound:

	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupPath"
	strcmp $R0 "" +2
  strcpy $INSTDIR $R0

	!insertmacro MUI_INSTALLOPTIONS_READ $R0 "iospecial.ini" "Settings" "NumFields"
	IntOp $R0 $R0 + 1
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Settings" "NumFields" $R0
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Field $R0" "Type" "label"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Field $R0" "Left" "120"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Field $R0" "Right" "315"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Field $R0" "Top" "174"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Field $R0" "Bottom" "186"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "iospecial.ini" "Field $R0" "Text" "Version ${Version}"

	Pop $R0

FunctionEnd


Function RunPaxon
	Exec '"$WINDIR\explorer.exe" "$INSTDIR\Paxon.exe"'
FunctionEnd


Function WelcomeShow
	Push $5
	GetDlgItem $5 $MUI_HWND 1203
	SetCtlColors $5 404040 transparent
	; ${MUI_BGCOLOR}
	Pop $5
FunctionEnd


Function InstallOptions

	Push $R0

	!insertmacro MUI_HEADER_TEXT $(IOTITLE2) $(IOTITLE3)

	!insertmacro MUI_INSTALLOPTIONS_WRITE "install.ini" "Field 1" "Text" $(FIELD1)

	!insertmacro MUI_INSTALLOPTIONS_WRITE "install.ini" "Field 2" "Text" $(FIELD2)
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupDesktopIcon"
	StrCmp $R0 "" 0 +2
	StrCpy $R0 "1"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "install.ini" "Field 2" "State" $R0

	!insertmacro MUI_INSTALLOPTIONS_WRITE "install.ini" "Field 3" "Text" $(FIELD3)
	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupRegisterFiletypes"
	StrCmp $R0 "" 0 +2
	StrCpy $R0 "1"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "install.ini" "Field 3" "State" $R0

	!insertmacro MUI_INSTALLOPTIONS_DISPLAY "install.ini"

	Pop $R0

FunctionEnd


;------------------------------------------------------------------------------
; Uninstaller Section
;------------------------------------------------------------------------------

Section "Uninstall"

	!insertmacro ApplicationData $R4

	!insertmacro MUI_INSTALLOPTIONS_READ $R5 "uninstall.ini" "Field 3" "State"

	SetShellVarContext "all"

	; ExecWait '"$INSTDIR\Paxon.exe" /unregserver'

	Delete "$INSTDIR\Paxon.exe"
	Delete "$INSTDIR\Paxon.fon"
	Delete "$INSTDIR\Paxon.chm"
	Delete "$INSTDIR\Paxon-EN.pxl"
	Delete "$INSTDIR\Paxon-FR.pxl"
	Delete "$INSTDIR\Uninstall.exe"

	Delete "$INSTDIR\Sound\Silence.pxs"
	Delete "$INSTDIR\Sound\Default Wave.pxs"
	Delete "$INSTDIR\Sound\Default PC-Speaker.pxs"

	; Only delete the bundled sound files; files the user put there,
	; and with them the folders, are kept

	Delete "$INSTDIR\Sound\Default\Paxon File Transfer Complete.wav"
	Delete "$INSTDIR\Sound\Default\Paxon Disconnected.wav"
	Delete "$INSTDIR\Sound\Default\Paxon Channel Switch.wav"
	Delete "$INSTDIR\Sound\Default\Paxon PGP Signature Valid.wav"
	Delete "$INSTDIR\Sound\Default\Paxon Ring.wav"
	Delete "$INSTDIR\Sound\Default\Paxon Connected (incoming).wav"
	Delete "$INSTDIR\Sound\Default\Paxon Connected (outgoing).wav"
	Delete "$INSTDIR\Sound\Default\Paxon Line Received (active).wav"
	Delete "$INSTDIR\Sound\Default\Paxon Line Received (inactive).wav"

	RMDir "$INSTDIR\Sound\Default"
	RMDir "$INSTDIR\Sound"
	RMDir "$INSTDIR"

	ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupStartMenu"
	StrCmp $R0 "" StartMenuDone
		Delete "$SMPROGRAMS\$R0\Paxon.lnk"
		RMDir "$SMPROGRAMS\$R0"
	StartMenuDone:

	Delete "$DESKTOP\Paxon.lnk"
	; Quick Launch shortcut of older installations
	Delete "$R4\Microsoft\Internet Explorer\Quick Launch\Paxon.lnk"

	RMDir /r "$R4\Ulf Haueisen\Paxon\Incomplete Files"

	StrCmp $R5 "1" 0 DontDeleteSettings1
		RMDir /r "$R4\Ulf Haueisen\Paxon"
		RMDir "$R4\Ulf Haueisen"
	DontDeleteSettings1:

	!insertmacro DeleteFileAssociation ".pxd" "Paxon.Database"
	!insertmacro DeleteFileAssociation ".pxf" "Paxon.IncompleteFile"
	!insertmacro DeleteFileAssociation ".pxi" "Paxon.IndexFile"
	!insertmacro DeleteFileAssociation ".pxl" "Paxon.LanguageResource"
	!insertmacro DeleteFileAssociation ".pxn" "Paxon.TextBuffer"
	!insertmacro DeleteFileAssociation ".pxs" "Paxon.SoundScheme"

	StrCmp $R5 "1" 0 DontDeleteSettings2
		DeleteRegKey HKCU "Software\Ulf Haueisen\Paxon"
		DeleteRegKey /ifempty HKCU "Software\Ulf Haueisen"
		DeleteRegKey HKLM "Software\Ulf Haueisen\Paxon"
		DeleteRegKey /ifempty HKLM "Software\Ulf Haueisen"
	DontDeleteSettings2:

	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\App Paths\Paxon.exe"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon"
	DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder\Start Menu2\Programs\Paxon"
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\App Management\ARPCache\Paxon"
	DeleteRegValue HKCU "Software\Microsoft\Windows\ShellNoRoam\MUICache" "$INSTDIR\Paxon.exe"

SectionEnd


;------------------------------------------------------------------------------
; Uninstaller Functions
;------------------------------------------------------------------------------

Function un.onInit

	ReadRegStr $LANGUAGE HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Paxon" "SetupLanguage"
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "uninstall.ini"

FunctionEnd


Function un.UninstallOptions

	!insertmacro MUI_HEADER_TEXT $(un.IOTITLE2) $(un.IOTITLE3)

	!insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 1" "Text" $(un.FIELD1)
	!insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 2" "Text" $(un.FIELD2)
	!insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 3" "Text" $(un.FIELD3)
	!insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 4" "Text" $(un.FIELD4)
	!insertmacro MUI_INSTALLOPTIONS_WRITE "uninstall.ini" "Field 5" "Text" $(un.FIELD5)

	!insertmacro MUI_INSTALLOPTIONS_DISPLAY "uninstall.ini"

FunctionEnd


Function un.GUIInit

	Push $R0

	UserInfo::GetAccountType
	Pop $R0
	StrCmp $R0 "Admin" GroupOk
	StrCmp $R0 "Power" GroupOk
	StrCmp $R0 "" GroupOk
	MessageBox MB_OK|MB_ICONEXCLAMATION $(un.MUSTBEADMIN)
	Abort
	GroupOk:

	PaxonTest:
	FindWindow $R0 "TApplication" "Paxon"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "TApplication" "Paxon Terminal"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "THauptfenster" "Paxon"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "THauptfenster" "Paxon Terminal"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "TMainWindow" "Paxon"
	StrCmp $R0 "0" 0 PaxonFound
	FindWindow $R0 "TMainWindow" "Paxon Terminal"
	StrCmp $R0 "0" 0 PaxonFound
	goto PaxonNotFound
	PaxonFound:
	MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION $(un.CLOSEPAXON) IDOK PaxonTest
	Abort
	PaxonNotFound:

	Pop $R0

FunctionEnd

;------------------------------------------------------------------------------
