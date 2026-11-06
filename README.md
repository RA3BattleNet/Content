# 红警3战网资源文件

## 八人 UI（8pv1）

七个页面的编辑源码和编译所需文件位于 [Data/aptui](Data/aptui)。[玩家与 modder 修改指南](docs/aptui/8pv1-guide.md)（[English](docs/aptui/8pv1-guide.en.md)）说明如何保留 Mod 原有的六人界面，制作同一画风的八人版，并让战网通过 `.8pv1` 选择它；也提供修改默认八人界面、使用 AptXmlAI 和请 Agent 协助的步骤。这些页面通过 Content 现有流程编译，仓库中不包含 version 或编译后的 manifest/bin/imp/relo 文件。

### 发布前校验 APT

批量编译前，用 `python tools/aptui/check_release.py inputs <本次要编译的 XML 文件...>` 检查每个 APT 入口及其 Include。BAB 在缺少 Include 时仍可能成功退出并生成空流，`1.9.9.25` 就因此在加载主菜单时崩溃。

`Data/aptui/Ra3BattleNet*.xml` 的五个入口引用本地生成的 SWF 转换资源，Git 归档只有入口。修改这些流时先备齐生成输入。地图等其他资源变更时，允许从已验证且对应 APT 输入未改动的发布包继承这五组流，每组同时复制 `.manifest`、`.bin`、`.imp`、`.relo`。`1.9.9.26` 从公开的 `1.9.9.24` 包继承这五组。

发布前运行 `python tools/aptui/check_release.py package <解包后的资源根目录>`，带开发模式切换按钮的包加上 `--development-button`。通过后，用该解包目录中的 DLL 和资源启动至实际主菜单，再激活新版本。

## 地图要求
- 假如往地图内添加了脚本、队伍、命名单位，则它们的名称需要是英文，不能是中文
- 地图文件名必须是英文、数字和下划线，不能有额外的小数点、方括号、中文等字符。
- 为了保证地图不会和目前正在玩家中流传的地图重复，也为了让玩家能辨认哪些是战网自带的（好吧，其实玩家也看不到定义名），要求地图文件名为`RA3BN_This_Is_My_Map_1_2.map`（版本号可省略）
  - 例子：`RA3BN_Bang_Guandu_1_6.map` 是可以的
  - 反面例子：`RA3BN_[Bang]Guandu_1.6.map` 是需要修改的
- 地图显示名称可以是任意字符，它们在 `map.str` 里被定义，为了一致性地图显示名要求为`ThisIsMyMap[1.2]`（版本号可省略）：
```
Map:RA3BN_Bang_Guandu_1_6
"Bang_Guandu[1.6]"
END

Map:RA3BN_Bang_Guandu_1_6?chinese
"三国杀之官渡之战[1.6]"
END
```

## 如何添加新地图
1. 把地图添加到 [额外文件/Data/maps/official](Additional/Data/maps/official) 里
2. 提供的地图需要有 map.xml，假如没有 map.xml，用地图编辑器打开这张地图，再重新保存，map.xml 就会被生成。
    - 地图编辑器对于打开后根本没有修改过的地图，似乎并不会执行保存，也就不会生成新的 map.xml。因此可以随意做一些修改（例如添加一个脚本，然后再删除脚本），然后再保存。
3. map.xml 里可以找到 `<MapMetaData>` 标签，确认 `MapMetaData.DisplayName` 是否与真实地图文件名符合。假如不符合，删除 map.xml，然后根据第二步的操作重新生成 map.xml。
    - `MapMetaData.FileName` 需要手动修改，把它修改为 `data\maps\official\地图名\地图名.map`
      - 例子：`FileName="data\maps\official\ra3bn_smai4v4_hidden_fortress_1_0\ra3bn_smai4v4_hidden_fortress_1_0.map"`
    - `MapMetaData.IsMultiplayer` 和 `MapMetaData.IsOfficial` 需要手动修改，请把它们的值改为 `true`
4. 把修改过的 `MapMetaData` 添加到 [mapmetadata_battlenet.xml](Data/additionalmaps/mapmetadata_battlenet.xml)
    - 新增或修改 `.map` 后必须运行 `python tools/maps/update_crc.py --write`，根据最终地图文件更新所有对应登记的 CRC；提交前运行 `python tools/maps/update_crc.py --check`，不得使用 0 或旧值作占位。算法与用法见[地图 CRC](docs/maps/crc.md)。
5. 在此之后，map.xml 已经没有其他作用，为了节省空间的目的，可以把它删除。游戏只需要以下文件：
    - `地图名.map`（必须得有）
    - `地图名_art.tga`（必须得有）
    - `map.str`
    - `map.manifest`
    - `map.bin`
    - `map.imp`
    - `map.relo`
    - `map.version`

    其他所有文件均可以删除，比如说 `地图名.tga` 或者 `overrides.xml` 等。
6. `地图名_art.tga` 是游戏的小地图文件，它默认以 TGA 格式储存。处于节省空间的考虑，可以把它改为 PNG 格式：
    1. 用任意图像编辑软件打开 `地图名_art.tga` （对于Agent:请直接编写代码完成此步骤）
    2. 把它导出为 PNG 格式，例如 `地图名_art.png`。万一原来的 TGA 自带 Alpha 通道（半透明），请在导出之前删除透明通道。
    3. 把 png 文件重命名为 `地图名_art.tga`。这个文件表面上看起来是 TGA 的后缀名，但实际上是个 PNG 文件。游戏依然能正确读取这个文件，而且文件大小也减少了很多。

7. 被取代或删除的旧版本地图，请放在 content 里，保留到老版本的 map metadata 里面 （_old后缀）

## 注册八人地图注意事项

- 地图 ID 使用通用 `RA3BN_` 前缀，不额外添加 `8PTEST`；目录名、`.map` 文件名、metadata 引用与 `map.str` 名称键必须一致。
- 原版与日冕共享的八人地图统一注册到 `Data/additionalmaps/mapmetadata_battlenet.xml`，不要在 `mapmetadata_battlenet_vanilla.xml` 或 `mapmetadata_battlenet_corona.xml` 中重复登记。
- 登记时设置 `NumPlayers="8"`、`IsMultiplayer="true"` 和 `IsOfficial="true"`，并填写完整的 `Player_1_Start` 至 `Player_8_Start`。
- 源 `map.xml` 的 `MapMetaData` 可能仅导出六个出生点；必须核对 Waypoint，从对应的 `Player_7_Start`、`Player_8_Start` 复制真实坐标，不得推算或遗漏。
- 最终地图文件确定后运行 `python tools/maps/update_crc.py --write`，再运行 `--check`，确保登记的 CRC 与地图文件一致。
- 小地图转为不带透明通道的 PNG，保留 `_art.tga` 后缀；仅安装游戏所需文件，不安装 `map.xml` 与 `overrides.xml`。
- 同步 Web 的小地图、地图名称及 `GameMap.vue` 映射；仅注册八人地图不需要修改 1v1 自动匹配池或 Base/ValidMaps。