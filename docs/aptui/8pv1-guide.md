# 修改 RA3BattleNet 八人 UI（8pv1）

简体中文 | [English](8pv1-guide.en.md)

如果你已经为自己的 Mod 制作了一套符合其风格的六人界面，启用红警3战网后却看到了战网的默认界面，这份指南会说明原因，并帮助你在原有界面上制作自己的八人版。你也可以让 AI Agent 按文中的示例协助完成。

**原来的六人版可以继续保留，八人版作为另一套资源加入同一个 Mod。** 不启用战网时，游戏继续使用原来的界面；启用战网时，则选择你的八人版。玩家不需要每次手动替换文件。

已有自定义六人界面的作者，可以先读下面的说明，再从第 5 节开始制作。想直接修改战网默认八人界面的玩家，可以从第 4 节开始。

## 1. 为什么原来的界面不显示了？

RA3 为每个页面使用一个很短的 `.version` 文本文件，指定要加载哪一套界面。例如，内容为 `.12` 时，游戏会查找该页面的 `.12` 文件。你的 Mod 可能使用 `.11`、`.12` 或其它后缀。

启用战网后，第 2 节列出的七个页面会优先选择 **`.8pv1`**。如果 Mod 只有原来的 `.11`／`.12`，没有对应的 `.8pv1`，游戏就会使用战网提供的默认八人界面。这种找不到自定义资源时使用默认资源的方式称为 **fallback**。

因此，画风变化是加载选择发生了变化：原来的六人资源仍然可以留在 Mod 中，不会因为战网选择 `.8pv1` 而被删除或改写。

| 使用方式 | 游戏选择的界面版本 | 显示结果 |
| --- | --- | --- |
| 未启用战网 | Mod 原有 `.version` 指定的版本，如 `.12` | 原来的自定义六人界面 |
| 启用战网，Mod 尚未提供 `.8pv1` | `.8pv1` | 战网默认八人界面 |
| 启用战网，Mod 已提供自己的 `.8pv1` | `.8pv1` | Mod 自己的八人界面 |

适配时，**保留原六人资源和原 `.version`，另外制作同一画风的 `.8pv1` 八人资源**，并将两套一起放进 Mod。战网会负责选择 `.8pv1`，不需要把 Mod 原来的 `.version` 永久改成它，也不必要求玩家手动切换两套文件。

`.8pv1` 是这套页面的文件命名约定；仅把旧文件改名，并不会自动增加两名玩家的位置和相关操作。下面的制作步骤会帮助你补齐布局和逻辑。

八人游戏功能由红警3战网（RA3BattleNet）提供，界面文件负责显示和操作。仅替换界面文件不会开启八人联机。

## 2. 仓库里有哪些输入

| 页面名（编译时保留大小写） | 用途 | Content 编译入口 |
| --- | --- | --- |
| `fe_m_assetsGameSetup` | 房间共用控件、地图出生点等 | `Data/aptui/fe_m_assetsgamesetup.8pv1.xml` |
| `fem_m_gameSetup` | 多人房间 | `Data/aptui/fem_m_gamesetup.8pv1.xml` |
| `fes_m_skirmishGameSetup` | 遭遇战设置 | `Data/aptui/fes_m_skirmishgamesetup.8pv1.xml` |
| `feg_m_disconnect` | 断线等待界面 | `Data/aptui/feg_m_disconnect.8pv1.xml` |
| `fem_m_load` | 加载界面 | `Data/aptui/fem_m_load.8pv1.xml` |
| `fem_m_postgameRoundup` | 结算统计 | `Data/aptui/fem_m_postgameroundup.8pv1.xml` |
| `igm_pauseMenu` | 暂停菜单玩家列表 | `Data/aptui/igm_pausemenu.8pv1.xml` |

共用下拉菜单沿用游戏原版，本次没有额外覆盖。

以暂停菜单为例：

```text
Data/aptui/
  igm_pausemenu.8pv1.xml             Content 的编译入口，决定输出文件名
  igm_pauseMenu/
    edit.xml                       主要编辑源：布局和动作指令
    igm_pauseMenu.xml              编译所需文件的清单（资产声明）
    igm_pauseMenu.apt               页面结构和动作代码
    igm_pauseMenu.const             配套常量
    igm_pauseMenu.dat               图片绑定等配套数据
    igm_pausemenu_geometry/*.ru     几何数据
    art/Textures/*.tga              纹理
```

`edit.xml` 用来编辑界面；`igm_pauseMenu.xml` 告诉编译器需要哪些文件；上层的 `igm_pausemenu.8pv1.xml` 决定最后生成的文件名。不要把这三种 XML 混用。修改 `edit.xml` 后，先用 AptXmlAI 生成 APT 和配套文件，再交给 Content 流程或 SDK 的 BinaryAssetBuilder 编译器。仓库保存这些制作输入，不提交最终的四个界面文件。

[`baseline/`](baseline/) 保存七页修改前的原版编辑 XML，供你或 Agent 对比八人界面改了哪些地方。

## 3. 准备工具

需要 Windows、Git、RA3 Mod SDK（含 `tools/BinaryAssetBuilder.exe`），以及 [AptXmlAI](https://git.ra3battle.cn/RA3CoronaDevelopers/AptXmlAI)。使用本文的辅助脚本时，还需要 Python 3.9 或更高版本，无须安装额外 Python 库。

在自己选择的工具目录运行：

```powershell
git clone https://git.ra3battle.cn/RA3CoronaDevelopers/AptXmlAI.git
& .\AptXmlAI\ra3apt-cli\ra3apt-cli.exe --version
```

仓库附带 Windows 可执行程序和配套的 `cc3tools` 转换工具，通常可以直接使用，不需要自己编译。下文中的 CLI 指这个命令行程序。工具更新后，请先阅读它的说明，并用一个小改动确认编译和重新展开都能正常完成。

如果需要从源码构建 CLI，可安装 Node.js 24／npm，在 `AptXmlAI/ra3apt-cli` 内运行：

```powershell
npm ci
npm test
npm run build:exe
```

先读 AptXmlAI 的 `AGENTS.md`、`APT修改指南.md` 和 `ra3apt-cli/README.md`。反编译得到的 ActionScript 可以辅助理解，但这里实际编辑、重新生成的源是 `edit.xml`，不是把参考 `.as` 文件直接编译回去。

## 4. 先试改一个现成页面

建议先从暂停菜单的一处位置、间距或标签开始，使用 Git 保存改前状态。直接修改 `Data/aptui/igm_pauseMenu/edit.xml`；需要换图时同时维护该页的纹理与绑定。

仓库提供了 [`build_page.py`](../../tools/aptui/build_page.py)，依次生成 APT、重新展开并比较编辑内容，再用 SDK 编译游戏可读取的文件。下面假设当前目录是 Content 根目录，请把工具路径改成自己的路径：

```powershell
python .\tools\aptui\build_page.py `
  --source .\Data\aptui\igm_pauseMenu\edit.xml `
  --name igm_pauseMenu `
  --aptxmlai C:\Tools\AptXmlAI `
  --sdk C:\Apps\RA3-MODSDK-X `
  --work .\.work\pause-ui-first-build
```

`--work` 必须是尚不存在的新目录。脚本不修改游戏、工具或输入目录。它按资产声明中的相对路径，从编辑源所在目录读取纹理；素材在别处时用 `--resources <素材根目录>` 指定。根目录的 DDS 或 `art/Textures` 下的 TGA 都可以；`--textures` 只用于另行指定 `art/Textures` 这类引用的来源目录。

成功后：

- `cli/` 是新生成的 APT／CONST／DAT／声明 XML／RU／纹理，`export.xml` 是重新展开的检查结果。
- `package/data/aptui/` 是给自定义 Mod 打包使用的 `.8pv1` 四个配套文件及必要的 .cdata 附加文件，不含 version。
- `logs/` 和 `receipt.json` 保存命令、结果与检查范围。

**提交 Content 时**，将通过检查的 `cli/` 内容（不含 `export.xml`）合入原页面子目录，保留编辑过的 `edit.xml`；确认资产声明不含本机绝对路径，删除经确认已不再引用的旧生成文件。保留对应的 `Data/aptui/<页面>.8pv1.xml` 入口，然后走 Content 自有编译流程。不要把 `package/`、缓存或本次临时目录提交进去。

Content 使用自己的编译与分发流程，不会自动打包成 BIG，也不包含或生成 `.version`。战网所需的版本选择文件随战网资源提供。

**给自己的 Mod 制作八人版时**，把 `package/` 下的 `data/` 树加入自己的 BIG，同时保留原来的六人文件和 `.version`。BIG 是 RA3 的资源包格式，必须由当前游戏实际加载。BIG 内应直接出现 `data/aptui/igm_pausemenu.8pv1.manifest` 等路径，不能多套 `package/`、`Additional/` 或 Mod 名称。SDK 项目采用 `Additional` 复制文件的流程时，可以把该 `data/` 树放到自己的 Mod 的 `Additional/` 下，再正常打包；具体仍以你的项目构建规则为准。

一个编译后的页面由 `manifest/bin/imp/relo` 四个文件组成。请完整加入同一次编译的四个文件和必要的 `.cdata` 附加文件；只加入其中一部分，可能会与默认界面的文件混用。战网保留游戏原有的资源查找顺序，已加载 BIG 中同路径、同名称的 `.8pv1` 文件优先于默认界面。修改 Mod 自己的 `.version` 不能改变战网对这七个页面的选择。

这些界面文件应放在 Mod 的 BIG 中。战网的 `priority` 目录用于优先选择版本，不是自定义界面的安装位置；把界面文件放进去会妨碍 BIG 覆盖。

脚本会检查重新展开后的布局和动作是否与编辑源一致、引用的素材是否齐全，以及输出的四个文件是否配套。这种“编译后再展开比较”的检查也称为往返检查。如果页面还依赖另一个资源包的 manifest，脚本会停止并提示需要另行处理。编译成功后，仍需进游戏确认显示与操作是否正常。

## 5. 从自己的六人界面制作八人版

目标是给自己的界面增加八人支持，同时保留 Mod 的画风和原来的六人版。先保存好当前可用的 Mod，在单独的工作目录里复制一份页面输入，用这份副本制作 `.8pv1`。本仓库的八人页面和改前原版可以帮助你或 Agent 找出需要增加的控件与逻辑。

1. 保留原 `.version` 及其选择的六人资源（例如 `.11` 或 `.12`），准备该页配套 APT、CONST、DAT、资产声明 XML、RU 和纹理的副本。如果手里只有 BIG，或从 BIG 中取出的 `manifest/bin/imp/relo`，需要先用资源提取工具还原这些制作输入；`ra3apt-cli expand` 读取的是 APT，不能直接读取 BIG 或这四个编译后文件。
2. 用当前 CLI 重新展开原页面，把原始输入和未修改的 XML 留作改前对照。
3. 对照修改前的原版 XML 和八人 `edit.xml`，找出玩家行数、对应控件、位置和隐藏多余行的修改，再移植到自己的页面。
4. 保留自己页面的画布、美术、阵营标签和读取游戏名单的逻辑。暂停名单应继续按实际名单显示；不要只加两个可见的空行。
5. 编译、重新展开、比较差异，再生成 `.8pv1` 界面文件。尤其核对 DAT 与纹理的对应、RU 几何文件的引用，以及未计划修改的素材是否保持不变。
6. 按第 4 节将生成的八人版加入 Mod BIG，保留原六人版及其 `.version`，然后分别检查未启用战网和启用战网时的效果。每个页面可以分别适配；尚未提供 `.8pv1` 的页面仍会使用战网默认界面。若要整套界面保持自己的风格，请逐页检查上表七个页面。

原始 CLI 命令例如：

```powershell
$cli = 'C:\Tools\AptXmlAI\ra3apt-cli\ra3apt-cli.exe'
$cc3tools = 'C:\Tools\AptXmlAI\ra3apt-cli\cc3tools'
New-Item -ItemType Directory -Path .\edit
& $cli expand .\input\igm_pauseMenu.apt `
  -o .\edit\edit.xml --tools-path $cc3tools
```

展开后把本页纹理按声明的相对目录配齐，再用上面的辅助脚本构建。CLI 的 `build` 会生成 APT、CONST、DAT、声明 XML 和 RU，纹理要另外提供；最终四个配套文件由 SDK BinaryAssetBuilder 生成。

**不要把所有数字 `6` 批量替换为 `8`。** 它们可能是颜色、帧、坐标或别的数量。也不要直接套用别的页面中的控件编号（如 sprite／character 的 ID）。同一含义的控件在不同 Mod 中可能使用完全不同的编号。

CLI 的输出 APT 必须保持原页面名，例如 `igm_pauseMenu.apt`。不要提前改成 `igm_pausemenu.8pv1.apt`，因为工具会用文件名生成页面内部引用的资源名称。`.8pv1` 加在最终资源文件名上；Content 通过入口文件名 `igm_pausemenu.8pv1.xml` 表达这个约定。

## 6. 直接交给 Agent 的示例

已有自定义六人界面时，把路径和想改的页面填清楚，再把下面整段发给 Agent：

> 我的 Mod 已有自定义六人 UI，希望保留原来的画风，另外制作启用 RA3BattleNet 时使用的八人版。先从 `<页面，例如暂停菜单>` 开始。Content 位于 `<路径>`，我的原页面完整输入位于 `<路径>`，AptXmlAI 位于 `<路径>`，RA3 Mod SDK 位于 `<路径>`。先阅读 Content 的 `docs/aptui/8pv1-guide.md`，以及 AptXmlAI 的 `AGENTS.md`、`APT修改指南.md` 和 CLI README。在独立目录中处理原页面的副本，保留原 `.version` 和它选择的六人资源（例如 `.11`／`.12`），只新增 `.8pv1` 八人版。对比 Content 中修改前的原版 XML 与八人编辑 XML，再展开我的原 APT。保留本 Mod 的画布、背景、阵营图标、纹理、几何和已有查询，增加八人所需的控件与逻辑，调整布局并保留隐藏多余行的判断；不要批量替换数字 6，也不要照搬控件编号。完成 CLI build→expand 比较和 SDK 编译，核对素材引用与四个输出文件是否配套。给我改后的编辑源码、配套编译输入、`.8pv1` 输出，以及需要加入 BIG 的路径清单。不要把界面文件放入 priority。测试说明应分别覆盖未启用战网时的原六人界面、启用战网时的自定义八人界面，以及战网内的六人兼容模式。先完成离线工作，不自动启动或部署到我的游戏；明确报告哪些已编译检查、哪些尚未在游戏验证。

只想调整现成 UI 时可用更短的要求：

> 请将 Content 的 `Data/aptui/igm_pauseMenu/edit.xml` 中 `<说明要改的位置、间距或图标>` 改为 `<目标效果>`，保持六／八人名单逻辑和其它美术不变。使用 `tools/aptui/build_page.py` 编译并检查往返差异，更新配套编译输入；不要提交 version、编译后的 manifest/bin/imp/relo 文件或缓存。给出修改说明与游戏内检查步骤。

让 Agent 先找到你想改的控件、做一处小改动并说明改了什么，通常比一次提出“把整个 UI 改成八人”更容易检查。遇到不支持的资源类型，应保留输入并说明具体限制，不要删除未知内容来凑过编译。

## 7. 游戏中怎样检查

修改资源或切换启动方式后，请重新启动游戏；游戏会缓存版本选择和页面，不能依赖即时刷新。已有六人界面的 Mod 至少检查以下三种情况：

| 检查场景 | 应看到的结果 |
| --- | --- |
| 未启用战网，照常启动 Mod | 原 `.version` 选择的六人界面仍然正常 |
| 启用战网，使用八人模式 | 自己的 `.8pv1` 界面正常显示和操作；分别检查少人数与满八人 |
| 启用战网，使用六人兼容模式 | 仍使用自己的 `.8pv1`，按该模式正确显示；不会切回原 `.11`／`.12` |

战网的六人兼容模式与未启用战网是两种情况。请保留页面按游戏模式和实际名单调整行数的逻辑；八人模式里即使只有两名玩家，也应继续容纳八名玩家，不能只按当前人数决定容量。

还要检查返回再进入同一页面。暂停菜单看姓名、颜色、阵营、败北状态和行数；房间看额外两槽的操作与地图点；加载和结算看额外槽位、空行及统计是否正确。

修改联机或回放界面时，应在相应真实场景验证。遭遇战能打开不代表联机、回放或整段加载过程已通过。若覆盖无效，先查 BIG 是否加载、内部路径是否正确、实际请求是否为 `.8pv1`，再查是否只替换了四个配套文件的一部分。

即使重新展开的 XML 没有差异，也要检查游戏内效果：转换工具可能舍入小数，且不能处理所有类型的声音元素。如果工具明确报出不支持的类型，请让 Agent 查明原因，不要直接删掉该元素。

资源来源和工具版本保存在 [provenance.json](provenance.json)，已有编译检查保存在 [validation.json](validation.json)。这些是供维护者追溯问题的记录，普通修改无须先阅读它们。
