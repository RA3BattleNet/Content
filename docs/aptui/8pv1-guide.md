# 修改 RA3BattleNet 八人 UI（8pv1）

这份指南面向想调整界面、为自己的 Mod 保留美术风格，或请 AI Agent 帮忙适配的玩家和 modder。可以直接从仓库中的八人页面开始，不必先学习整个游戏引擎。

当前提交的是原版风格八人 UI 的 **v6 制作版本**，游戏使用的资源后缀仍是 **`.8pv1`**。v6 是素材迭代批次，8pv1 是加载时约定的名称。只换 UI 不会让原版游戏拥有八人联机能力；实际槽位和数据仍由支持八人的 Native 提供。

## 1. 游戏怎样选中这些页面

RA3 的 `.version` 是很短的文本文件，用来选择同名资源流的后缀。例如：

```text
data/aptui/igm_pausemenu.version       内容为 .12
                  ↓
data/aptui/igm_pausemenu.12.manifest
data/aptui/igm_pausemenu.12.bin
data/aptui/igm_pausemenu.12.imp
data/aptui/igm_pausemenu.12.relo
```

这四个文件一起组成一个编译后的页面。把 version 的内容换为 `.8pv1`，引擎就会请求 `igm_pausemenu.8pv1.*`。开头的点也是内容的一部分；Native 发布包使用 ASCII `.8pv1` 加 CRLF 换行，共 7 字节。

RA3BattleNet 的加载顺序是：

```text
Native 的 priority 快照 → 游戏原有搜索路径（包括已加载的 Mod BIG）→ NativeDll 所在目录
```

Native 启动时将 `priority` 中的文件读入名为 `bnprio:` 的内存快照。发布包在这里放了下表七个页面的 `.version`，强制选择 `.8pv1`。真正的 UI 放在 Native 目录下的普通 `data/aptui`，作为找不到自定义页面时的默认资源，也就是 fallback。

所以，**Mod BIG 中同路径、同名称的 `.8pv1` 页面可以覆盖默认八人 UI**。BIG 必须被当前游戏实际加载；仅把文件放在某个未加载的 BIG 中不会生效。Native 保留原搜索路径内部的顺序，并不重新排列不同 Mod 的优先级。

这是逐文件查找，并不是自动把四个文件视为一组。覆盖一个页面时，请一起提供同一次编译的 `manifest/bin/imp/relo`，以及确实用到的附加资源，避免新旧文件混搭。

- 不要把 UI 四件流放进 `priority`，否则会抢在 Mod BIG 前面。
- BIG 中的 `.version` 无法胜过已经由 priority 选中的七个 version。Modder 应提供自己的 `.8pv1` 页面，而不是试图用 version 改回 `.12`。
- 可以保留 Mod 原有 `.12` 等默认页面及其 `.version`，供没有启用八人加载方式的环境使用。
- priority 是启动时快照，页面本身也有缓存。改完后重新启动测试实例，不能依赖即时刷新。

**Content 仓库不包含这些 `.version`，也不负责生成它们。** 它们由 Native 发布包提供。Content 使用自己的编译与分发流程，不会因为文件放在这里就打包成 BIG；上面的 BIG 做法是给自定义 Mod 使用的。

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
  igm_pausemenu.8pv1.xml             Content 的流入口，决定输出后缀
  igm_pauseMenu/
    edit.xml                       主要编辑源：布局和动作指令
    igm_pauseMenu.xml              资产声明，列出下面各项
    igm_pauseMenu.apt               页面结构和动作代码
    igm_pauseMenu.const             配套常量
    igm_pauseMenu.dat               图片绑定等配套数据
    igm_pausemenu_geometry/*.ru     几何数据
    art/Textures/*.tga              纹理
```

这些输入沿用现有 UI 的“入口 XML + 子目录”结构；仓库不提交编译后的四件流。`edit.xml` 不是 SDK 的资产声明，不能直接交给 BinaryAssetBuilder。修改它之后先用 AptXmlAI 生成 APT 和配套输入，再交给 Content 流程或 SDK 编译。

[`baseline/`](baseline/) 保留七页修改前的原版编辑 XML，供 Agent 对比哪些变化是八人适配所需。[`provenance.json`](provenance.json) 记录来源提交、工具版本及输入哈希，方便维护者核对素材批次。

六人兼容模式也使用同一套 `.8pv1` 资源，并不会切回旧后缀。设置页通过 `Ra3BN_UI8Mode` 获取六／八行；加载页根据 `LOAD_INFO_PRESENT` 的实际数组长度隐藏多余行；暂停页按引擎返回的实际名单显示。**八人模式里只有两名玩家，也仍然可以是八人模式。** 不要根据当前人数自行猜测引擎模式。

## 3. 准备工具

需要 Windows、Git、RA3 Mod SDK（含 `tools/BinaryAssetBuilder.exe`），以及 [AptXmlAI](https://git.ra3battle.cn/RA3CoronaDevelopers/AptXmlAI)。使用本文的辅助脚本时，还需要 Python 3.9 或更高版本，无须安装额外 Python 库。

在自己选择的工具目录运行：

```powershell
git clone https://git.ra3battle.cn/RA3CoronaDevelopers/AptXmlAI.git
& .\AptXmlAI\ra3apt-cli\ra3apt-cli.exe --version
```

仓库附带 Windows EXE 和配套 `cc3tools`，通常不需要自己编译。本文核对的版本是 CLI 1.0.1，AptXmlAI 提交 `28485a48243ab50b73177a94b83250d8d421789c`。要重现本次工具环境，可在克隆目录执行 `git checkout 28485a48243ab50b73177a94b83250d8d421789c`；使用后续版本时重新核对工具说明与往返结果。

如果需要从源码构建 CLI，可安装 Node.js 24／npm，在 `AptXmlAI/ra3apt-cli` 内运行：

```powershell
npm ci
npm test
npm run build:exe
```

先读 AptXmlAI 的 `AGENTS.md`、`APT修改指南.md` 和 `ra3apt-cli/README.md`。反编译得到的 ActionScript 可以辅助理解，但这里实际编辑、重新生成的源是 `edit.xml`，不是把参考 `.as` 文件直接编译回去。

## 4. 先试改一个现成页面

建议先从暂停菜单的一处位置、间距或标签开始，使用 Git 保存改前状态。直接修改 `Data/aptui/igm_pauseMenu/edit.xml`；需要换图时同时维护该页的纹理与绑定。

仓库提供了 [`build_page.py`](../../tools/aptui/build_page.py)，把 CLI 编译、重展开比较、SDK 编译连在一起。下面假设当前目录是 Content 根目录，请把工具路径改成自己的路径：

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
- `package/data/aptui/` 是给自定义 Mod 打包使用的 `.8pv1` 四件流及必要 CDATA，不含 version。
- `logs/` 和 `receipt.json` 保存命令、结果与检查范围。

**提交 Content 时**，将通过检查的 `cli/` 内容（不含 `export.xml`）合入原页面子目录，保留编辑过的 `edit.xml`；确认资产声明不含本机绝对路径，删除经确认已不再引用的旧生成文件。保留对应的 `Data/aptui/<页面>.8pv1.xml` 入口，然后走 Content 自有编译流程。不要把 `package/`、缓存或本次临时目录提交进去。

**给自己的 Mod 制作覆盖时**，把 `package/` 下的 `data/` 树放进会被游戏加载的 BIG；BIG 内应直接出现 `data/aptui/igm_pausemenu.8pv1.manifest` 等路径，不能多套 `package/`、`Additional/` 或 Mod 名称。SDK 项目采用 `Additional` 复制文件的流程时，可以把该 `data/` 树放到自己的 Mod 的 `Additional/` 下，再正常打包；具体仍以你的项目构建规则为准。

脚本会核对有序 XML 往返、声明引用的输入是否存在、四件流是否齐全且标记匹配。它针对自包含页面；遇到外部 manifest 依赖会明确停止，不会悄悄漏打。它没有检查每一个编译后资产，也没有代替游戏运行验证。

## 5. 在自己的 UI 上保留原有风格

不要用原版风格八人页面直接盖掉自己 Mod 的背景与阵营图标。应从自己页面的完整输入开始，把八人所需的逻辑与布局移植进去。

1. 准备该页配套 APT、CONST、DAT、资产声明 XML、RU 和纹理。只有最终 BIG 四件流时，先通过你使用的资源工具提取为这些输入；四件流不是 `ra3apt-cli expand` 的直接输入。
2. 用当前 CLI 重新展开原页面，把原始输入和未修改的 XML 留作比较基线。
3. 对照仓库中的原版基线和八人 `edit.xml`，识别该页的容量、行实例、布局和可见性处理，再移植到自己的页面。
4. 保留自己页面的画布、美术、阵营标签、行实例类型和原有查询。暂停名单应继续按实际返回的名单长度显示；不要只加两个可见的空行。
5. 编译、重展开、比较预期差异，再编译最终流。尤其核对 DAT 与纹理的对应、RU 引用，以及未计划修改的素材是否保持不变。

原始 CLI 命令例如：

```powershell
$cli = 'C:\Tools\AptXmlAI\ra3apt-cli\ra3apt-cli.exe'
$cc3tools = 'C:\Tools\AptXmlAI\ra3apt-cli\cc3tools'
New-Item -ItemType Directory -Path .\edit
& $cli expand .\input\igm_pauseMenu.apt `
  -o .\edit\edit.xml --tools-path $cc3tools
```

展开后把本页纹理按声明的相对目录配齐，再用上面的辅助脚本构建。CLI 的 `build` 会生成 APT、CONST、DAT、声明 XML 和 RU，纹理要另外提供；最终四件流由 SDK BinaryAssetBuilder 生成。

**不要把所有数字 `6` 批量替换为 `8`。** 它们可能是颜色、帧、坐标或别的数量。也不要直接套用别的页面的 sprite／character 编号。同一含义的控件在不同 Mod 中可能使用完全不同的编号。

CLI 的输出 APT 必须保持原页面名，例如 `igm_pauseMenu.apt`。不要提前改成 `igm_pausemenu.8pv1.apt`，因为工具会用文件名生成资产 ID。`.8pv1` 加在最终流名上；Content 通过入口文件名 `igm_pausemenu.8pv1.xml` 表达这个约定。

## 6. 直接交给 Agent 的示例

先把路径和想改的效果填清楚，再把下面整段发给 Agent：

> 请帮我将自己的暂停菜单适配为 RA3BattleNet `.8pv1` 八人 UI。Content 位于 `<路径>`，我的原页面完整输入位于 `<路径>`，AptXmlAI 位于 `<路径>`，RA3 Mod SDK 位于 `<路径>`。先阅读 Content 的 `docs/aptui/8pv1-guide.md`，以及 AptXmlAI 的 `AGENTS.md`、`APT修改指南.md` 和 CLI README。对比 Content 的原版基线与八人编辑 XML，再展开我的原 APT。保留本 Mod 的画布、背景、阵营图标、纹理、几何和已有查询，只移植八槽容量、行布局与必要的可见性处理；不要批量替换数字 6，也不要照搬控件编号。在独立目录完成 CLI build→expand 比较、SDK 编译，并核对所有素材引用和四件流配套关系。给我改后的编辑源码、配套编译输入、`.8pv1` 输出以及简短测试步骤。保留原 `.version` 和默认后缀资源，不将流文件放入 priority。先完成离线工作，不自动启动或部署到我的游戏；明确报告哪些已编译检查、哪些尚未在游戏验证。

只想调整现成 UI 时可用更短的要求：

> 请将 Content 的 `Data/aptui/igm_pauseMenu/edit.xml` 中 `<说明要改的位置、间距或图标>` 改为 `<目标效果>`，保持六／八人名单逻辑和其它美术不变。使用 `tools/aptui/build_page.py` 编译并检查往返差异，更新配套编译输入；不要提交 version、最终四件流或缓存。给出修改说明与游戏内检查步骤。

让 Agent 先确认一处控件的归属、做小改动并出示差异，通常比一次提出“把整个 UI 改成八人”更容易检查。遇到不支持的资源类型，应保留输入并说明具体限制，不要删除未知内容来凑过编译。

## 7. 游戏中怎样检查

重新启动自己的测试实例后，至少检查少人数、满八人、六人兼容模式，以及返回再进入同一页面。暂停菜单看姓名、颜色、阵营、败北状态和行数；房间看额外两槽的操作与地图点；加载和结算看额外槽位、空行及统计是否正确。

修改联机或回放界面时，应在相应真实场景验证。遭遇战能打开不代表联机、回放或整段加载过程已通过。若覆盖无效，先查 BIG 是否加载、内部路径是否正确、实际请求是否为 `.8pv1`，再查是否只替换了四件流的一部分。

XML 往返相同也不代表 APT 字节完全相同：当前工具会归一化部分浮点数和标签，且有明确不支持的 sound character。新素材需单独验证视觉与交互。

本次 Content 导入不启动游戏、不部署资源；导入和离线构建结果见 [validation.json](validation.json)。此前有限双版本测试已确认 version 选择、BIG 优先及 Native fallback，但不能据此宣称全部加载字段或 Online／Replay 场景已验收。
