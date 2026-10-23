# Editing the RA3BattleNet Eight-Player UI (8pv1)

[简体中文](8pv1-guide.md) | English

This guide is for players and modders who want to adjust the interface, keep their mod's visual style, or ask an AI agent to help with the adaptation. You can start with the eight-player pages in this repository without first learning the entire game engine.

This repository provides an eight-player interface in the original game's style. Its resource files use the **`.8pv1`** suffix. RA3BattleNet provides eight-player multiplayer support. Replacing interface files alone does not enable this support.

## 1. How the game selects these pages

In RA3, a `.version` file is a short text file that selects which set of interface files to load. For example:

```text
data/aptui/igm_pausemenu.version       contains .12
                  ↓
data/aptui/igm_pausemenu.12.manifest
data/aptui/igm_pausemenu.12.bin
data/aptui/igm_pausemenu.12.imp
data/aptui/igm_pausemenu.12.relo
```

These four files together form a compiled page. Changing the version file's contents to `.8pv1` makes the game request `igm_pausemenu.8pv1.*`. The leading dot is part of the contents.

RA3BattleNet already selects `.8pv1` for the seven pages listed below. Players and modders do not need to edit their version files. Once a version is selected, the game searches for the page files in this order:

```text
The game's existing resource paths (including loaded mod BIGs) → RA3BattleNet's default eight-player interface
```

The default interface provided by RA3BattleNet is used only when no custom page is found. This is called fallback loading. BIG is RA3's resource archive format; you can put your modified interface files in your mod's BIG.

Therefore, **a `.8pv1` page in a mod BIG can override the default eight-player UI if its path and filename match**. The BIG must actually be loaded by the running game; placing files in an unloaded BIG has no effect. RA3BattleNet preserves the game's existing resource search order and does not rearrange the priority of different mods.

Files are looked up individually; the game does not automatically treat the four files as a single set. When overriding a page, include the `manifest/bin/imp/relo` files from the same build, together with any additional resources they need. Avoid mixing files from different builds.

- `priority` is the directory from which RA3BattleNet reads version selection files first. Do not put compiled interface files there, as doing so would prevent mod BIGs from taking priority over them.
- A `.version` file in a BIG cannot change the version RA3BattleNet selects for these seven pages. Modders should provide their own `.8pv1` pages instead of trying to use a version file to switch back to `.12`.
- You can keep your mod's original default pages, such as `.12`, and their `.version` files for use without RA3BattleNet's eight-player functionality.
- Both version selections and pages are cached. Restart the game after making changes; do not expect them to reload immediately.

**The Content repository does not contain or generate these `.version` files.** They are supplied with RA3BattleNet's resources. Content has its own build and distribution process; placing files in this repository does not automatically package them into a BIG. The BIG instructions above are for custom mods.

## 2. What the repository contains

| Page name (preserve capitalization when building) | Purpose | Content build entry |
| --- | --- | --- |
| `fe_m_assetsGameSetup` | Shared lobby controls, map starting positions, and related elements | `Data/aptui/fe_m_assetsgamesetup.8pv1.xml` |
| `fem_m_gameSetup` | Multiplayer lobby | `Data/aptui/fem_m_gamesetup.8pv1.xml` |
| `fes_m_skirmishGameSetup` | Skirmish setup | `Data/aptui/fes_m_skirmishgamesetup.8pv1.xml` |
| `feg_m_disconnect` | Disconnection waiting screen | `Data/aptui/feg_m_disconnect.8pv1.xml` |
| `fem_m_load` | Loading screen | `Data/aptui/fem_m_load.8pv1.xml` |
| `fem_m_postgameRoundup` | Postgame statistics | `Data/aptui/fem_m_postgameroundup.8pv1.xml` |
| `igm_pauseMenu` | Player list in the pause menu | `Data/aptui/igm_pausemenu.8pv1.xml` |

The shared dropdown menu uses the original game resource; no additional override is included here.

For example, the pause menu has this structure:

```text
Data/aptui/
  igm_pausemenu.8pv1.xml             Content build entry; determines the output filename
  igm_pauseMenu/
    edit.xml                       Main editing source: layout and action instructions
    igm_pauseMenu.xml               List of files needed for compilation (asset declaration)
    igm_pauseMenu.apt               Page structure and action code
    igm_pauseMenu.const             Companion constants
    igm_pauseMenu.dat               Image bindings and other supporting data
    igm_pausemenu_geometry/*.ru     Geometry data
    art/Textures/*.tga              Textures
```

Use `edit.xml` to edit the interface. `igm_pauseMenu.xml` tells the compiler which files it needs, while the parent-level `igm_pausemenu.8pv1.xml` determines the final output filename. Do not confuse these three kinds of XML. After editing `edit.xml`, use AptXmlAI to generate the APT and its companion files, then compile them through Content's build process or the SDK's BinaryAssetBuilder. The repository stores these source inputs, not the final four interface files.

[`baseline/`](baseline/) contains the original, unmodified editing XML for the seven pages, so you or an agent can compare what changed for the eight-player interface.

Six-player compatibility mode uses the same `.8pv1` pages; there is no need to swap files. The existing pages adjust the displayed rows according to the game mode and actual player list. Preserve these checks when editing: **an eight-player game with only two players is still in eight-player mode**. The number of players currently present must not be the only factor that determines the page's capacity.

## 3. Prepare the tools

You need Windows, Git, the RA3 Mod SDK (including `tools/BinaryAssetBuilder.exe`), and [AptXmlAI](https://git.ra3battle.cn/RA3CoronaDevelopers/AptXmlAI). The helper script in this guide also requires Python 3.9 or later, with no additional Python packages.

Run the following in a tools directory of your choice:

```powershell
git clone https://git.ra3battle.cn/RA3CoronaDevelopers/AptXmlAI.git
& .\AptXmlAI\ra3apt-cli\ra3apt-cli.exe --version
```

The repository includes a Windows executable and the accompanying `cc3tools` converters. You can normally use them directly without compiling them yourself. In this guide, CLI means this command-line program. After updating the tools, read their documentation and try a small edit to confirm that building and re-expanding still work.

If you need to build the CLI from source, install Node.js 24 and npm, then run the following in `AptXmlAI/ra3apt-cli`:

```powershell
npm ci
npm test
npm run build:exe
```

Read AptXmlAI's `AGENTS.md`, `APT修改指南.md` (the APT editing guide), and `ra3apt-cli/README.md` first. Decompiled ActionScript can help you understand the code, but the source you edit and rebuild here is `edit.xml`; the reference `.as` files are not compiled directly back into the page.

## 4. Try a small edit to an existing page

Start with one position, spacing adjustment, or label in the pause menu, and use Git to save the original state. Edit `Data/aptui/igm_pauseMenu/edit.xml` directly. If you replace an image, also update the page's textures and bindings as needed.

The repository includes [`build_page.py`](../../tools/aptui/build_page.py). It generates the APT, re-expands it and compares the editable contents, then uses the SDK to compile files the game can read. The following example assumes you are in the Content repository root. Replace the tool paths with your own:

```powershell
python .\tools\aptui\build_page.py `
  --source .\Data\aptui\igm_pauseMenu\edit.xml `
  --name igm_pauseMenu `
  --aptxmlai C:\Tools\AptXmlAI `
  --sdk C:\Apps\RA3-MODSDK-X `
  --work .\.work\pause-ui-first-build
```

`--work` must be a new directory that does not already exist. The script does not modify the game, tools, or input directory. It reads textures from the editing source's directory, following the relative paths in the asset declaration. If the assets are elsewhere, use `--resources <asset-root-directory>`. Both DDS files in the root directory and TGA files under `art/Textures` are supported. Use `--textures` only to specify an alternative source directory for references under `art/Textures`.

After a successful build:

- `cli/` contains the generated APT, CONST, DAT, declaration XML, RU files, and textures. `export.xml` is the re-expanded result used for checking.
- `package/data/aptui/` contains the four matching `.8pv1` files and any required `.cdata` sidecar files for packaging in a custom mod. It contains no version file.
- `logs/` and `receipt.json` record the commands, results, and scope of the checks.

**When contributing to Content**, copy the checked contents of `cli/` (excluding `export.xml`) into the original page subdirectory, keeping your edited `edit.xml`. Confirm that the asset declaration contains no absolute paths to your computer, and remove old generated files only after confirming that they are no longer referenced. Keep the corresponding `Data/aptui/<page>.8pv1.xml` entry and use Content's own build process. Do not commit `package/`, caches, or the temporary working directory.

**When creating an override for your own mod**, put the `data/` tree from `package/` into a BIG that the game will load. Paths such as `data/aptui/igm_pausemenu.8pv1.manifest` must appear directly inside the BIG, without an extra `package/`, `Additional/`, or mod-name folder. If your SDK project copies files from `Additional`, you can place the `data/` tree in your mod's `Additional/` directory and package it normally. Follow your project's build rules.

The script checks that the re-expanded layout and actions match the editing source, that the referenced assets are present, and that the four output files belong together. This build-and-re-expand comparison is also called a round-trip check. If the page depends on another resource package's manifest, the script stops and reports that it needs separate handling. A successful build still needs in-game checks for appearance and interaction.

## 5. Preserve your own UI's style

Do not replace your mod's background and faction icons with the entire original-style eight-player page. Start with your own page's complete inputs and bring across the logic and layout changes needed for eight players.

1. Gather the page's matching APT, CONST, DAT, asset declaration XML, RU files, and textures. If you only have a BIG, or the `manifest/bin/imp/relo` files extracted from one, use a resource extraction tool to recover these source inputs first. `ra3apt-cli expand` reads APT files; it cannot read BIGs or the four compiled files directly.
2. Re-expand the original page with the current CLI. Keep the original inputs and unmodified XML for comparison.
3. Compare the original XML with the eight-player `edit.xml`. Identify the changes to player row counts, related controls, positions, and logic that hides unused rows, then apply them to your own page.
4. Preserve your page's canvas, artwork, faction labels, and logic for reading the game's player list. The pause menu should continue to display the actual list; do not simply add two visible empty rows.
5. Build, re-expand, and compare the differences, then generate the final interface files. Pay particular attention to DAT-to-texture bindings, references to RU geometry files, and whether assets you did not intend to change remain unchanged.

For example, you can run the CLI directly:

```powershell
$cli = 'C:\Tools\AptXmlAI\ra3apt-cli\ra3apt-cli.exe'
$cc3tools = 'C:\Tools\AptXmlAI\ra3apt-cli\cc3tools'
New-Item -ItemType Directory -Path .\edit
& $cli expand .\input\igm_pauseMenu.apt `
  -o .\edit\edit.xml --tools-path $cc3tools
```

After expanding, supply the page's textures at the relative paths in the declaration, then build with the helper script above. The CLI's `build` command generates APT, CONST, DAT, declaration XML, and RU files; you must supply the textures separately. The SDK's BinaryAssetBuilder generates the final four matching files.

**Do not replace every `6` with `8`.** Those numbers may represent colors, frames, coordinates, or unrelated counts. Do not copy control IDs (such as sprite or character IDs) directly from another page either. Controls with the same purpose may have completely different IDs in different mods.

The CLI's output APT must keep the original page name, such as `igm_pauseMenu.apt`. Do not rename it to `igm_pausemenu.8pv1.apt` at this stage: the tool uses the filename to generate resource names referenced inside the page. Add `.8pv1` to the final resource filenames. Content expresses this naming convention through the entry filename `igm_pausemenu.8pv1.xml`.

## 6. Example requests for an agent

Fill in the paths and the result you want, then send the following request to your agent:

> Please adapt my pause menu for the RA3BattleNet `.8pv1` eight-player UI. Content is at `<path>`, my original page's complete inputs are at `<path>`, AptXmlAI is at `<path>`, and the RA3 Mod SDK is at `<path>`. First read Content's `docs/aptui/8pv1-guide.en.md`, along with AptXmlAI's `AGENTS.md`, `APT修改指南.md`, and CLI README. Compare the original XML in Content with the eight-player editing XML, then expand my original APT. Preserve my mod's canvas, background, faction icons, textures, geometry, and existing queries. Add only the rows needed to accommodate eight players, adjust the layout, and preserve the logic that hides unused rows. Do not replace all occurrences of the number 6 or copy control IDs blindly. In a separate directory, complete the CLI build→expand comparison and SDK compilation, and check all asset references and that the four output files belong together. Give me the edited source, matching build inputs, `.8pv1` output, and brief test steps. Keep the original `.version` and default-suffix resources, and do not put compiled interface files in priority. Complete the offline work first without automatically starting or deploying to my game. Clearly report what has passed build checks and what has not yet been tested in the game.

For a small change to an existing UI, you can use this shorter request:

> In Content's `Data/aptui/igm_pauseMenu/edit.xml`, change `<describe the position, spacing, or icon>` to `<desired result>`, keeping the six/eight-player list logic and other artwork unchanged. Use `tools/aptui/build_page.py` to build and check for round-trip differences, then update the matching build inputs. Do not commit version files, compiled manifest/bin/imp/relo files, or caches. Provide a description of the changes and in-game checks.

Asking the agent to locate the control you want, make one small change, and explain it is usually easier to review than asking it to "make the entire UI support eight players" at once. If it encounters an unsupported resource type, it should preserve the inputs and explain the specific limitation, rather than deleting unknown content just to make the build pass.

## 7. What to check in the game

After restarting the game, check at least a game with few players, a full eight-player game, six-player compatibility mode, and leaving and reopening the same page. In the pause menu, check names, colors, factions, defeated status, and row counts. In the lobby, check interactions with the two extra slots and map starting positions. On the loading and postgame screens, check the extra slots, empty rows, and statistics.

When editing multiplayer or replay interfaces, test those actual scenarios. A page opening in skirmish does not prove that multiplayer, replays, or the full loading sequence work correctly. If an override has no effect, first check that the BIG is loaded, its internal paths are correct, and the requested version is `.8pv1`. Then check whether you replaced only some of the four matching files.

Even if the re-expanded XML has no differences, check the result in the game. The converters may round decimal values and cannot handle every type of sound element. If a tool explicitly reports an unsupported type, ask the agent to investigate the cause instead of deleting that element.

Resource origins and tool versions are recorded in [provenance.json](provenance.json), and completed build checks are recorded in [validation.json](validation.json). These records help maintainers investigate problems; you do not need to read them before making an ordinary edit.
