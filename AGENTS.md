# 如何添加新地图

装图流程（命名规则、放入地图、生成 map.xml、注册元数据、精简文件、map.str 格式等）见 [README.md](README.md)。

## 元数据 XML 放哪里

`Data/additionalmaps/` 下多份 mapmetadata，**更新/新增必须与同系列原图注册在同一类 XML**：

| 文件 | 用途 |
|------|------|
| `mapmetadata_battlenet.xml` | 战网常规匹配池（现行） |
| `mapmetadata_battlenet_old.xml` | 战网常规池的旧版地图 |
| `mapmetadata_battlenet_corona.xml` | **日冕（Corona）** 池（现行） |
| `mapmetadata_battlenet_corona_old.xml` | 日冕池旧版 |
| `mapmetadata_battlenet_vanilla.xml` | 原版/Archon 等 |
| `mapmetadata_battlenet_vanilla_old.xml` | 原版池旧版 |

规则：

1. **先查原图在哪份 XML**（搜 `DisplayName`），新版本写进**同一份现行 XML**；被替换的旧 id 挪到对应的 `*_old.xml`（文件目录保留，不重命名）。
2. **Ore（散矿）变体一律注册到日冕**：`mapmetadata_battlenet_corona.xml`（不是 `mapmetadata_battlenet.xml`）。
3. 地图实体仍放在 `Additional/Data/maps/official/<mapId>/`，与池无关；池只由 metadata 决定。

## map.str 命名补充

**更新地图时：显示名必须与旧版一致，只改版本号。**

- 英文：`MapName[版本号]`（无版本号可省略括号段）
- 中文：`中文名(English Name)[版本号]`
- 示例（旧 1.1 → 新 1.2）：
  - 旧：`"Redemption Base[1.1]"` / `"救赎基地(Redemption Base)[1.1]"`
  - 新：`"Redemption Base[1.2]"` / `"救赎基地(Redemption Base)[1.2]"`

### Ore（散矿）变体

- 文件 id / 目录名：`RA3BN_<原图英文名>_Ore_<版本>`（id 仍用 `Ore`；与显示名无关）
- metadata：一律 `mapmetadata_battlenet_corona.xml`
- **版本号与对应正图相同**
- **显示名必须以 U+FEFF（UTF-8：`EF BB BF`）开头**，让散矿在客户端列表里排到最后；肉眼不可见，改 str 时务必用 hex 核对
- 英文显示名：`\uFEFF[CorOre] Map Name[版本号]`（`[CorOre]` 后有一个空格）
- 中文显示名：`\uFEFF[散矿]中文名[版本号]`（`[散矿]` 后无空格；禁止在中文串写 `Ore`）
- 示例（正图 `RA3BN_Redemption_Base_1_2`）：
  - id：`RA3BN_Redemption_Base_Ore_1_2`
  - EN：`"\uFEFF[CorOre] Redemption Base[1.2]"`
  - ZH：`"\uFEFF[散矿]救赎基地[1.2]"`

---

## Web 前端同步

新增地图后需同步更新 Web 前端（网站地图名称和小地图），涉及另一个 Git 仓库。**修改前必须找用户提供 Web 仓库的本地路径。**

### 需要同步的内容

#### 1. 小地图图片
- Content 中的小地图文件为 `地图名_art.tga`，虽然后缀是 `.tga`，实际格式可能是 PNG 或 TGA（不能仅凭后缀假定）
- 先判断文件真实格式（Magic Number：PNG 为 `89 50 4E 47`，JPG 为 `FF D8 FF`，TGA 尾部有 `TRUEVISION-XFILE` 标记），再决定处理方式
- 转换后放入 Web 仓库的 `Ra3.BattleNet.Frontend/src/assets/img/map/`
- 文件命名：`<mapId>.jpg`，即与 Content 中的 `.map` 文件名一致（不含扩展名和路径），后缀 `.jpg`
- 例如：`ra3bn_aquae_caerulea.jpg`、`ra3bn_archon_temple_prime_1_6.jpg`、`Bang_Guandu.jpg`

#### 2. 地图本地化名称
- 目标文件：Web 仓库 `Ra3.BattleNet.Frontend/public/gamestrings/en.str` 和 `zh-CN.str`
- Content 中大部分地图自带 `map.str`，包含现成的 `Map:xxx` 和 `Map:xxx?chinese` 条目
- **仅复制地图名称条目**（`Map:xxx` / `Map:xxx?chinese` 块），不要复制 `SCRIPT:`、`DESC:` 等其他本地化内容
- 仅当 `map.str` 中实际包含地图名称条目时才复制
- `en.str` 中键前缀用 `Map:`，`zh-CN.str` 用 `Map:xxx?chinese` 格式
- 对比 Content 中已有的地图与前端的 str 文件，若发现 Content 中有地图在前端 str 里缺失名称，应提示用户补充

#### 3. GameMap.vue 组件
- Web 仓库 `Ra3.BattleNet.Frontend/src/components/game/GameMap.vue`
- 该文件通过 `v-else-if` 硬编码了 `mapId` 到小地图图片的映射，新增地图需在此添加对应分支

#### 4. useMapParser.ts（可选）
- Web 仓库 `Ra3.BattleNet.Frontend/src/composables/useMapParser.ts`
- 如果新地图属于某个匹配池（如 Archon 1v1），需在对应的硬编码数组中加入地图路径
