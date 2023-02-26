# 红警3战网资源文件

## 地图要求
- 假如往地图内添加了脚本、队伍、命名单位，则它们的名称需要是英文，不能是中文
- 地图文件名必须是英文、数字和下划线，不能有额外的小数点、方括号、中文等字符。
- 为了保证地图不会和目前正在玩家中流传的地图重复，也为了让玩家能辨认哪些是战网自带的，要求地图文件名为`RA3BN_This_Is_My_Map_1_2.map`（版本号可省略）
  - 例子：`RA3BN_Bang_Guandu_1_6.map` 是可以的
  - 反面例子：`RA3BN_[Bang]Guandu_1.6.map` 是需要修改的
- 地图显示名称可以是任意字符，它们在 `map.str` 里被定义，为了一致性地图显示名要求为`[RA3BN]ThisIsMyMap[1.2]`（版本号可省略）：
例如：
```
Map:RA3BN_Bang_Guandu_1_6
"[RA3BN]Bang_Guandu[1.6]"
END

Map:RA3BN_Bang_Guandu_1_6?chinese
"[RA3BN]三国杀之官渡之战[1.6]"
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
    1. 用任意图像编辑软件打开 `地图名_art.tga`
    2. 把它导出为 PNG 格式，例如 `地图名_art.png`。万一原来的 TGA 自带 Alpha 通道（半透明），请在导出之前删除透明通道。
    3. 把 png 文件重命名为 `地图名_art.tga`。这个文件表面上看起来是 TGA 的后缀名，但实际上是个 PNG 文件。游戏依然能正确读取这个文件，而且文件大小也减少了很多。
