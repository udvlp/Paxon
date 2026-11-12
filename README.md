**English** | [Deutsch](README.de.md)

# Paxon – Packet Radio Terminal

Paxon is a terminal program for amateur radio **packet radio**, written in Object Pascal
(Delphi 7) for Windows. Development started in 1996, and it was widely used in the
German-speaking packet radio network.

* **Version:** 3.0 (build 3000)
* **Platform:** Windows, 32-bit; runs without administrator rights, tested on Windows 11
* **Language:** Object Pascal / Delphi 7, VCL
* **License:** [MIT](LICENSE.md)

Paxon is no longer actively developed. Version 3.0 is a revision for the release as free
software: bugs fixed, third-party components with unclear licenses replaced, source code
cleaned up.

The user interface is available in German, English and French.

---

## Features

**Connections**

* Several simultaneous channels with channel switching, monitor and status line
* Station database with callsigns, notes, passwords (user/sysop) and automatic password
  response
* Remote commands: control your own station over the radio link
* Several own callsigns with SSIDs

**File transfer**

* Send: AutoBIN, DIDADIT, text
* Receive: AutoBIN, DIDADIT, 7Plus, GoText
* Send queue, templates, splitting of large files (BinSplit), pre- and post-processing,
  CRC and MD5 checks
* Send files by drag and drop from Explorer

**PGP**

* Signing and encryption through the PGP SDK, key ring access, verification of incoming
  signatures

**TNC or modem connection**

* **FlexNet** via `flxapi32.dll`
* **Hostmode** over a serial port: TFPCX, TF and WA8DED-compatible TNCs
* **TFWin** (experimental)

**User interface**

* German, English and French
* Configurable sounds, colors and fonts; terminal fonts included

---

## Runtime requirements

* Windows (settings are stored under `HKEY_CURRENT_USER\Software\Ulf Haueisen\Paxon`)
* Depending on the configured device: FlexNet (`flxapi32.dll`), TFWin or a serial TNC in
  hostmode
* For PGP: PGP 6.5.8 (freeware)

FlexNet, TFWin and PGP are separate programs by their respective authors. They are not part
of this repository.

---

## Directories

| Path                         | Contents                                                          |
| ---------------------------- | ----------------------------------------------------------------- |
| `Build.cmd`                  | Builds everything from a fresh clone (see below)                  |
| `src/*.pas`, `src/*.dfm`     | Source code and forms of the main program                         |
| `src/Paxon.dpr`              | Project file (Delphi 7), with `Paxon.dof` and `Paxon.cfg`         |
| `src/Paxon.bpg`              | Project group: program and both language DLLs                     |
| `src/VCL/paxon/`             | Own components (`src/`) and the package `PaxonComponents.dpk`     |
| `src/VCL/tbxthemes/`         | Office XP theme and status bar from TBX (MIT license)             |
| `src/ENU/`, `src/FRA/`       | Sources of the language DLLs (English, French)                    |
| `src/Resources/`             | Bitmaps, icons, images, RTF texts and the application manifest    |
| `src/*.rc`, `src/MakeRes.cmd`| Resource scripts and the script that builds the `.res` from them  |
| `src/Font/`                  | Terminal fonts (`Paxon.fon` and the individual bitmap fonts)      |
| `src/Sound/`                 | Bundled sound schemes (`*.pxs`) and sounds                        |
| `Setup/`                     | Installer (NSIS script, license texts)                            |
| `DebugMonitor/`              | Shows Paxon's debug output (only with `PAXON_DEBUG`)              |
| `Tools/MakeSounds.py`        | Generates the default sounds in `src/Sound/Default/` (Python 3)   |

`Bin/` and `Temp/` are created by the build and are not part of the repository.

All source files are encoded in **Windows-1252**, not UTF-8. German umlauts may therefore
look garbled in the GitHub preview.

---

## Building

You need **Delphi 7**. The code requires a compiler older than Delphi 2009 (`String` is an
ANSI string). All required components are in the repository and are found through the search
paths in `src/Paxon.dof` and `src/Paxon.cfg`; the remaining units are part of Delphi 7.

`Build.cmd` builds everything from a fresh clone (`dcc32` from Delphi 7 must be on the path,
or set `DCC32` to its full path):

```bat
Build.cmd
```

It creates `Bin/` and `Temp/`, compiles `Paxon.exe`, the two language DLLs, the component
package and `DebugMonitor.exe`, and puts everything Paxon needs to run into `Bin/`: `Paxon.exe`, `Paxon.fon`, `Paxon-EN.pxl` and `Paxon-FR.pxl`. No installer
is needed; without one, Paxon simply starts without a sound scheme.

To build only the program by hand, create `Bin/` and `Temp/` first (dcc32 does not create
them), run `dcc32 -B -Q Paxon.dpr` in `src/` and copy `src/Font/Paxon.fon` next to
`Paxon.exe`; Paxon does not start without it.

For the Delphi IDE, `src/VCL/paxon/PaxonComponents.dpk` contains the own components and the
TBX theme. The package must be installed to open the forms in the designer.

**Resources:** The `.res` files are in the repository. After changing `src/*.rc` or files
under `src/Resources/`, `src/MakeRes.cmd` rebuilds them (`brcc32` from Delphi 7 must be on the
path).

**Language DLLs:** Run `dcc32 -B -Q Paxon.dpr` in `src/ENU/` and `src/FRA/`. This produces
`Bin/Paxon.ENU` and `Bin/Paxon.FRA`; they are shipped as `Paxon-EN.pxl` and `Paxon-FR.pxl`
next to `Paxon.exe`. Paxon loads a language DLL only if its version matches the version of
`Paxon.exe` exactly.

**Installer:** Needs NSIS 3. After `Build.cmd`, `makensis Setup\Paxon.nsi` writes
`Bin\SetupPaxon<build>.exe`. The script reads the version from `Bin\Paxon.exe` and gives the
installer the same version information.

### Maintaining the translations

The language DLLs are resource DLLs of Delphi's Integrated Translation Environment (ITE).
`src/ENU/` and `src/FRA/` hold the translated forms (`*.dfm`), the translation repositories
(`*.dfn`) and the translated `resourcestring`s (`Paxon_DRC.rc`). After changing forms or
`resourcestring`s of the main program:

1. Open `src/Paxon.bpg` in Delphi 7 and build `Paxon.exe`. Its linker setting "detailed map
   file" also writes `Paxon.drc`, which the ITE needs for the `resourcestring`s.
2. *Project | Languages | Update Resource DLLs* takes over the changes into `src/ENU/` and
   `src/FRA/`.
3. *View | Translation Manager* lists new and changed entries; translate them there.
4. Build `Paxon.ENU` and `Paxon.FRA` and copy them as `Paxon-EN.pxl` and `Paxon-FR.pxl`
   next to `Paxon.exe`.

The IDs in `Paxon_DRC.rc` change with every build that adds or removes `resourcestring`s, so
the language DLLs must always be updated together with `Paxon.exe`. The version number is set
in the project options (*Project | Options | Version Info*) of `Paxon`, `Paxon.ENU` and
`Paxon.FRA`; the IDE writes it into each project's `Paxon.res`. All three must be the same.

---

## License

Paxon is licensed under the **MIT License**, see [LICENSE.md](LICENSE.md).

Bundled third-party components keep their licenses:

* **TBX Office XP theme and status bar:** Yury Plashenkov and other TBX authors, MIT
  (`src/VCL/tbxthemes/LICENSE`). `ToolbarU.pas` follows the drawing rules of TBX and says so in
  its header.

The interface units `FlexnetApiU.pas` and `PGPApiU.pas` follow the C headers of FlexNet
(DK7WJ) and the PGPsdk.

## Author

Copyright 1996–2026 Ulf Haueisen, DG1FAZ, <ulf@paxon.app>
