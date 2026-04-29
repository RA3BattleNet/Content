# 如何添加新地图

## 命名规则
- 地图文件名：英文、数字、下划线；**不能**有小数点、方括号、中文
- 格式：`RA3BN_This_Is_My_Map_1_2.map`（版本号用下划线分隔，可省略）
- 反面例子：`RA3BN_[Bang]Guandu_1.6.map` 不行
- 地图显示名由 `map.str` 定义，版本号格式：`ThisIsMyMap[1.2]`

## 添加步骤

### 1. 放入地图文件
将地图目录放入 `Additional/Data/maps/official/`

### 2. 生成 map.xml
用地图编辑器打开地图 → 随意做点小改动（如加删脚本）→ 保存，编辑器会生成 `map.xml`。确认 `<MapMetaData>` 中：
- `FileName` 手动改为 `data\maps\official\地图目录名\地图名.map`
- `IsMultiplayer` 和 `IsOfficial` 改为 `true`

### 3. 注册到元数据
将修改过的 `<MapMetaData>` 片段添加到 `Data/additionalmaps/mapmetadata_battlenet.xml` 的 `<MapMetaData id="TheBattleNetMapCache">` 节点下。

### 4. 精简文件
最终只保留：
- `地图名.map`（必须）
- `地图名_art.tga`（必须，可将 PNG 改名伪装成 TGA 以节省空间）
- `map.str`、`map.manifest`、`map.bin`、`map.imp`、`map.relo`、`map.version`
- 其他文件（如 `地图名.tga`、`overrides.xml`、`map.xml`）可删除

### 5. map.str 格式
```
Map:RA3BN_Your_Map_Name
"YourMapDisplayName[1.0]"
END

Map:RA3BN_Your_Map_Name?chinese
"中文显示名[1.0]"
END
```

## 注意事项
- 地图内脚本、队伍、命名单位的名称必须用英文，不能是中文
- 显示名可以是任意字符（包括中文），在 `map.str` 中定义

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
