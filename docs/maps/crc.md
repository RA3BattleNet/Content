# 地图 CRC

新增或修改 `.map` 后，必须为全部对应的 MapMetaData 登记更新 `CRC`，包括旧版池及跨池重复登记，不能沿用 0 或旧文件的值。地图最终保存、命名和注册完成后，在仓库根目录运行（Python 3.9+，无需额外依赖）：

```shell
python tools/maps/update_crc.py --write
python tools/maps/update_crc.py --check
```

`--write` 根据 `Additional/Data/maps/official/` 中的实际文件更新 `Data/additionalmaps/mapmetadata_*.xml`，缺少 CRC 属性时补上。`--check` 只检查，全部相符返回 0；CRC 不符、缺少地图文件或地图未登记时返回 1。两种模式都会先核对所有文件引用；缺图或漏登记时不会开始写入。Windows 风格的 metadata 路径按大小写不敏感匹配，工具也可在 Linux 上运行。

只会更改 CRC 属性，原有池归属、XML 格式、注释和其他属性保留。检查通过后，将 `.map` 修改和所有受影响的 metadata 一起提交；不要手动用非零占位值替代计算。工具不修改地图文件、不解压或重新保存地图，也不生成编译资源。

这里使用游戏的地图文件校验算法：Retail `0x52C180` 以 4096 字节分块读取虚拟文件，`0x92F110` 对每个无符号字节累积：

```text
h = ((h << 1) + (h >> 31) + byte) & 0xFFFFFFFF
```

初值为 0，输入为最终 `.map` 文件的原始字节，不包含 `map.str`、小地图或其他文件。该算法不是标准 CRC32，不能使用 `zlib.crc32` 等库替代。数值按无符号十进制写入 metadata；如果实际计算结果为 0，仍保留真实结果。

MapMetaData 注册时直接使用该 `CRC`，不会因为它是 0 而自动读取地图文件补算。这与仿真不同步的 CRC 是不同用途。

工具修改后的回归检查：

```shell
python -B -m unittest discover -s tools/maps -p "test_*.py"
```
