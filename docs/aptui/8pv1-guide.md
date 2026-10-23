# 修改 RA3BattleNet 八人 UI（8pv1）

这份指南面向想调整界面、为自己的 Mod 保留美术风格，或请 AI Agent 帮忙适配的玩家和 modder。可以直接从仓库中的八人页面开始，不必先学习整个游戏引擎。

本仓库提供与原版风格一致的八人界面，资源文件使用 **`.8pv1`** 后缀。八人联机功能由红警3战网（RA3BattleNet）提供；仅替换界面文件，不会让未启用战网八人功能的游戏支持八人联机。

## 1. 游戏怎样选中这些页面

RA3 的 `.version` 是很短的文本文件，用来指定要加载哪一组界面文件。例如：

```text
data/aptui/igm_pausemenu.version       内容为 .12
                  ↓
data/aptui/igm_pausemenu.12.manifest
data/aptui/igm_pausemenu.12.bin
data/aptui/igm_pausemenu.12.imp
data/aptui/igm_pausemenu.12.relo
```

这四个文件一起组成一个编译后的页面。把 version 的内容换为 `.8pv1`，游戏就会请求 `igm_pausemenu.8pv1.*`。开头的点也是内容的一部分。

战网已经为下表七个页面指定了 `.8pv1`，玩家和 modder 无须自己修改 version。选定版本后，游戏按以下顺序查找对应的页面文件：

```text
游戏原有资源路径（包括已加载的 Mod BIG）→ 战网提供的默认八人界面
```

找不到自定义页面时，才会使用战网提供的默认界面。这种后备加载方式也称为 fallback。BIG 是 RA3 使用的资源包格式，可以把修改后的界面文件放进自己的 Mod BIG 中。

所以，**Mod BIG 中同路径、同名称的 `.8pv1` 页面可以覆盖默认八人 UI**。BIG 必须被当前游戏实际加载；仅把文件放在某个未加载的 BIG 中不会生效。战网保留游戏原有的资源查找顺序，不会重新排列不同 Mod 的优先级。

这是逐文件查找，并不是自动把四个文件视为一组。覆盖一个页面时，请一起提供同一次编译的 `manifest/bin/imp/relo`，以及确实用到的附加资源，避免新旧文件混搭。

- `priority` 是战网优先读取版本选择文件的目录。不要把编译后的界面文件放进去，否则 Mod BIG 就无法优先覆盖它们。
- BIG 中的 `.version` 不能更改战网为这七个页面指定的版本。Modder 应提供自己的 `.8pv1` 页面，而不是试图用 version 改回 `.12`。
- 可以保留 Mod 原有 `.12` 等默认页面及其 `.version`，供没有启用战网八人功能的环境使用。
- 版本选择和页面都会被缓存。改完后重新启动游戏，不能依赖即时刷新。

**Content 仓库不包含这些 `.version`，也不负责生成它们。** 它们随战网资源一起提供。Content 使用自己的编译与分发流程，不会因为文件放在这里就打包成 BIG；上面的 BIG 做法是给自定义 Mod 使用的。

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

六人兼容模式也使用同一套 `.8pv1` 页面，不需要另外换文件。现有页面会根据游戏模式和实际名单调整显示行数。修改时请保留这些判断：**八人模式里即使只有两名玩家，也仍是八人模式**；不能只根据当前人数决定页面能容纳多少人。

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

**给自己的 Mod 制作覆盖时**，把 `package/` 下的 `data/` 树放进会被游戏加载的 BIG；BIG 内应直接出现 `data/aptui/igm_pausemenu.8pv1.manifest` 等路径，不能多套 `package/`、`Additional/` 或 Mod 名称。SDK 项目采用 `Additional` 复制文件的流程时，可以把该 `data/` 树放到自己的 Mod 的 `Additional/` 下，再正常打包；具体仍以你的项目构建规则为准。

脚本会检查重新展开后的布局和动作是否与编辑源一致、引用的素材是否齐全，以及输出的四个文件是否配套。这种“编译后再展开比较”的检查也称为往返检查。如果页面还依赖另一个资源包的 manifest，脚本会停止并提示需要另行处理。编译成功后，仍需进游戏确认显示与操作是否正常。

## 5. 在自己的 UI 上保留原有风格

不要用原版风格八人页面直接盖掉自己 Mod 的背景与阵营图标。应从自己页面的完整输入开始，把八人所需的逻辑与布局移植进去。

1. 准备该页配套 APT、CONST、DAT、资产声明 XML、RU 和纹理。如果手里只有 BIG，或从 BIG 中取出的 `manifest/bin/imp/relo`，需要先用资源提取工具还原这些制作输入；`ra3apt-cli expand` 读取的是 APT，不能直接读取 BIG 或这四个编译后文件。
2. 用当前 CLI 重新展开原页面，把原始输入和未修改的 XML 留作改前对照。
3. 对照修改前的原版 XML 和八人 `edit.xml`，找出玩家行数、对应控件、位置和隐藏多余行的修改，再移植到自己的页面。
4. 保留自己页面的画布、美术、阵营标签和读取游戏名单的逻辑。暂停名单应继续按实际名单显示；不要只加两个可见的空行。
5. 编译、重新展开、比较差异，再生成最终界面文件。尤其核对 DAT 与纹理的对应、RU 几何文件的引用，以及未计划修改的素材是否保持不变。

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

先把路径和想改的效果填清楚，再把下面整段发给 Agent：

> 请帮我将自己的暂停菜单适配为 RA3BattleNet `.8pv1` 八人 UI。Content 位于 `<路径>`，我的原页面完整输入位于 `<路径>`，AptXmlAI 位于 `<路径>`，RA3 Mod SDK 位于 `<路径>`。先阅读 Content 的 `docs/aptui/8pv1-guide.md`，以及 AptXmlAI 的 `AGENTS.md`、`APT修改指南.md` 和 CLI README。对比 Content 中修改前的原版 XML 与八人编辑 XML，再展开我的原 APT。保留本 Mod 的画布、背景、阵营图标、纹理、几何和已有查询，只增加容纳八名玩家所需的行数，调整布局并保留隐藏多余行的逻辑；不要批量替换数字 6，也不要照搬控件编号。在独立目录完成 CLI build→expand 比较、SDK 编译，并核对所有素材引用和四个输出文件是否配套。给我改后的编辑源码、配套编译输入、`.8pv1` 输出以及简短测试步骤。保留原 `.version` 和默认后缀资源，不将编译后的界面文件放入 priority。先完成离线工作，不自动启动或部署到我的游戏；明确报告哪些已编译检查、哪些尚未在游戏验证。

只想调整现成 UI 时可用更短的要求：

> 请将 Content 的 `Data/aptui/igm_pauseMenu/edit.xml` 中 `<说明要改的位置、间距或图标>` 改为 `<目标效果>`，保持六／八人名单逻辑和其它美术不变。使用 `tools/aptui/build_page.py` 编译并检查往返差异，更新配套编译输入；不要提交 version、编译后的 manifest/bin/imp/relo 文件或缓存。给出修改说明与游戏内检查步骤。

让 Agent 先找到你想改的控件、做一处小改动并说明改了什么，通常比一次提出“把整个 UI 改成八人”更容易检查。遇到不支持的资源类型，应保留输入并说明具体限制，不要删除未知内容来凑过编译。

## 7. 游戏中怎样检查

重新启动游戏后，至少检查少人数、满八人、六人兼容模式，以及返回再进入同一页面。暂停菜单看姓名、颜色、阵营、败北状态和行数；房间看额外两槽的操作与地图点；加载和结算看额外槽位、空行及统计是否正确。

修改联机或回放界面时，应在相应真实场景验证。遭遇战能打开不代表联机、回放或整段加载过程已通过。若覆盖无效，先查 BIG 是否加载、内部路径是否正确、实际请求是否为 `.8pv1`，再查是否只替换了四个配套文件的一部分。

即使重新展开的 XML 没有差异，也要检查游戏内效果：转换工具可能舍入小数，且不能处理所有类型的声音元素。如果工具明确报出不支持的类型，请让 Agent 查明原因，不要直接删掉该元素。

资源来源和工具版本保存在 [provenance.json](provenance.json)，已有编译检查保存在 [validation.json](validation.json)。这些是供维护者追溯问题的记录，普通修改无须先阅读它们。
