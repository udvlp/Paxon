[English](README.md) | **Deutsch**

# Paxon – Packet-Radio-Terminal

Paxon ist ein Terminalprogramm für **Packet Radio** im Amateurfunk, geschrieben in Object
Pascal (Delphi 7) für Windows. Es entstand ab 1996 und war im deutschsprachigen
Packet-Radio-Netz verbreitet.

* **Version:** 3.1 (Build 3012)
* **Plattform:** Windows, 32 Bit; läuft ohne Administratorrechte, geprüft unter Windows 11
* **Sprache:** Object Pascal / Delphi 7, VCL
* **Lizenz:** [MIT](LICENSE.md)

Paxon wird nicht mehr aktiv weiterentwickelt. Version 3.0 ist eine Überarbeitung für die
Veröffentlichung als freie Software: Fehler behoben, Fremdkomponenten mit unklarer Lizenz
ersetzt, Quelltext aufgeräumt.

---

## Funktionen

**Verbindungen**

* Mehrere gleichzeitige Kanäle mit Kanalumschaltung, Monitor und Statuszeile
* Stationsdatenbank mit Rufzeichen, Notizen, Passwörtern (Benutzer/Sysop) und
  automatischer Passwortantwort
* Remote-Befehle: Fernsteuerung der eigenen Station über die Funkstrecke
* Mehrere eigene Rufzeichen mit SSIDs

**Dateiübertragung**

* Senden: AutoBIN, DIDADIT, Text
* Empfangen: AutoBIN, DIDADIT, 7Plus, GoText
* Sendewarteschlange, Vorlagen, Aufteilen großer Dateien (BinSplit), Vor- und
  Nachbearbeitung, CRC- und MD5-Prüfung
* Dateien per Drag-and-Drop aus dem Explorer senden

**PGP**

* Signieren und Verschlüsseln über die PGP-SDK, Zugriff auf den Schlüsselbund, Prüfung
  eingehender Signaturen

**Anbindung an TNC oder Modem**

* **FlexNet** über `flxapi32.dll`
* **Hostmode** seriell: TFPCX, TF und WA8DED-kompatible TNCs
* **TFWin** (experimentell)

**Oberfläche**

* Deutsch, Englisch und Französisch
* Einstellbare Klänge, Farben und Schriften; mitgelieferte Terminalschriften

---

## Voraussetzungen zur Laufzeit

* Windows (Einstellungen liegen unter `HKEY_CURRENT_USER\Software\Ulf Haueisen\Paxon`)
* Je nach eingerichtetem Gerät: FlexNet (`flxapi32.dll`), TFWin oder ein serieller TNC im
  Hostmode
* Für PGP: PGP 6.5.8 (Freeware)

FlexNet, TFWin und PGP sind eigenständige Programme ihrer jeweiligen Autoren. Sie sind nicht
Teil dieses Repositorys.

---

## Verzeichnisse

| Pfad                         | Inhalt                                                             |
| ---------------------------- | ------------------------------------------------------------------ |
| `Build.cmd`                  | Baut alles aus einem frischen Clone (siehe unten)                  |
| `src/*.pas`, `src/*.dfm`     | Quelltext und Formulare des Hauptprogramms                         |
| `src/Paxon.dpr`              | Projektdatei (Delphi 7), dazu `Paxon.dof` und `Paxon.cfg`          |
| `src/Paxon.bpg`              | Projektgruppe: Programm und beide Sprach-DLLs                      |
| `src/VCL/paxon/`             | Eigene Komponenten (`src/`) und das Paket `PaxonComponents.dpk`    |
| `src/VCL/tbxthemes/`         | Gestaltungsschema Office XP und Statusleiste aus TBX (MIT-Lizenz)  |
| `src/ENU/`, `src/FRA/`       | Quellen der Sprach-DLLs (englisch, französisch)                    |
| `src/Resources/`             | Bitmaps, Icons, Bilder, RTF-Texte und das Anwendungsmanifest       |
| `src/*.rc`, `src/MakeRes.cmd`| Ressourcenskripte und das Skript, das daraus die `.res` erzeugt    |
| `src/Font/`                  | Terminalschriften (`Paxon.fon` und die einzelnen Bitmap-Schriften) |
| `src/Sound/`                 | Mitgelieferte Klangschemata (`*.pxs`) und Klänge                   |
| `Setup/`                     | Installer (NSIS-Skript, Lizenztexte)                               |
| `DebugMonitor/`              | Zeigt die Debug-Ausgaben von Paxon (nur mit `PAXON_DEBUG`)         |
| `Tools/MakeSounds.py`        | Erzeugt die Standardklänge in `src/Sound/Default/` (Python 3)      |

`Bin/` und `Temp/` entstehen beim Bauen und gehören nicht zum Repository.

Alle Quelldateien sind **Windows-1252**-kodiert, nicht UTF-8. Umlaute erscheinen in der
Vorschau von GitHub deshalb teilweise verstümmelt.

---

## Übersetzen

Benötigt wird **Delphi 7**. Der Code setzt einen Compiler vor Delphi 2009 voraus (`String` ist
ein ANSI-String). Alle benötigten Komponenten liegen im Repository und werden über die
Suchpfade in `src/Paxon.dof` und `src/Paxon.cfg` gefunden; die übrigen Units gehören zu
Delphi 7.

`Build.cmd` baut alles aus einem frischen Clone (`dcc32` aus Delphi 7 muss im Suchpfad
liegen, oder `DCC32` enthält den vollen Pfad):

```bat
Build.cmd
```

Das Skript legt `Bin/` und `Temp/` an, übersetzt `Paxon.exe`, die beiden Sprach-DLLs, das
Komponentenpaket und `DebugMonitor.exe` und legt alles, was Paxon zum Laufen braucht, nach
`Bin/`: `Paxon.exe`, `Paxon.fon`, `Paxon-EN.pxl` und
`Paxon-FR.pxl`. Ein Installer ist nicht nötig; ohne ihn startet Paxon nur ohne Klangschema.

Wer nur das Programm von Hand übersetzt, legt vorher `Bin/` und `Temp/` an (dcc32 tut das
nicht), ruft in `src/` `dcc32 -B -Q Paxon.dpr` auf und kopiert `src/Font/Paxon.fon` neben
`Paxon.exe`; ohne sie startet Paxon nicht.

Für die Delphi-IDE enthält `src/VCL/paxon/PaxonComponents.dpk` die eigenen Komponenten und
das TBX-Schema. Das Paket muss installiert sein, damit sich die Formulare im Designer öffnen
lassen.

**Ressourcen:** Die `.res`-Dateien liegen im Repository. Nach Änderungen an `src/*.rc` oder
an Dateien unter `src/Resources/` erzeugt `src/MakeRes.cmd` sie neu (`brcc32` aus Delphi 7
muss im Suchpfad liegen).

**Sprach-DLLs:** In `src/ENU/` bzw. `src/FRA/` jeweils `dcc32 -B -Q Paxon.dpr` aufrufen. Das
ergibt `Bin/Paxon.ENU` bzw. `Bin/Paxon.FRA`; ausgeliefert werden sie als `Paxon-EN.pxl` und
`Paxon-FR.pxl` neben `Paxon.exe`. Paxon lädt eine Sprach-DLL nur, wenn ihre Version genau
zur `Paxon.exe` passt.

**Installer:** Braucht NSIS 3. Nach `Build.cmd` schreibt `makensis Setup\Paxon.nsi` den
Installer `Bin\SetupPaxon<Build>.exe`. Das Skript liest die Version aus `Bin\Paxon.exe` und
gibt dem Installer dieselbe Versionsinformation.

### Übersetzungen pflegen

Die Sprach-DLLs sind Ressourcen-DLLs der Übersetzungsumgebung von Delphi (ITE). `src/ENU/`
und `src/FRA/` enthalten die übersetzten Formulare (`*.dfm`), die Übersetzungsspeicher
(`*.dfn`) und die übersetzten `resourcestring`s (`Paxon_DRC.rc`). Nach Änderungen an
Formularen oder `resourcestring`s des Hauptprogramms:

1. `src/Paxon.bpg` in Delphi 7 öffnen und `Paxon.exe` übersetzen. Durch die
   Linker-Einstellung „detaillierte Map-Datei“ entsteht dabei auch `Paxon.drc`, die die ITE
   für die `resourcestring`s braucht.
2. *Project | Languages | Update Resource DLLs* übernimmt die Änderungen nach `src/ENU/` und
   `src/FRA/`.
3. *View | Translation Manager* zeigt neue und geänderte Einträge; dort übersetzen.
4. `Paxon.ENU` und `Paxon.FRA` übersetzen und als `Paxon-EN.pxl` und `Paxon-FR.pxl` neben
   `Paxon.exe` legen.

Die IDs in `Paxon_DRC.rc` ändern sich, sobald `resourcestring`s hinzukommen oder wegfallen.
Die Sprach-DLLs müssen deshalb immer zusammen mit der `Paxon.exe` erneuert werden. Die
Versionsnummer steht in den Projektoptionen (*Project | Options | Version Info*) von `Paxon`,
`Paxon.ENU` und `Paxon.FRA`; die IDE schreibt sie in die `Paxon.res` des jeweiligen Projekts.
Alle drei müssen übereinstimmen.

---

## Lizenz

Paxon steht unter der **MIT-Lizenz**, siehe [LICENSE.md](LICENSE.md).

Mitgelieferte Fremdkomponenten behalten ihre Lizenzen:

* **TBX-Schema Office XP und Statusleiste:** Yury Plashenkov und weitere TBX-Autoren, MIT
  (`src/VCL/tbxthemes/LICENSE`). `ToolbarU.pas` folgt beim Zeichnen den Regeln von TBX und nennt
  das in seinem Kopf.

Die Schnittstellen-Units `FlexnetApiU.pas` und `PGPApiU.pas` folgen den C-Headern von FlexNet
(DK7WJ) bzw. der PGPsdk.

## Autor

Copyright 1996–2026 Ulf Haueisen, DG1FAZ, <ulf@paxon.app>
