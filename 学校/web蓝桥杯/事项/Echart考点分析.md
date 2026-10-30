---
tags:
  - 前端/ECharts
  - 前端/JavaScript
  - 蓝桥云课
  - 学习方法
---

# ECharts 官网怎么用：按蓝桥杯考点学

> [!info] 这份笔记解决什么
> 蓝桥杯 Web 应用开发赛项把 ECharts 列为考点：**基础语法、绘制图表、异步数据加载和更新、交互组件、事件处理**。
> 官网（[echarts.apache.org](https://echarts.apache.org/zh/index.html)）就是最好的开卷资料，但入口多、字段多。这份笔记把「考什么 → 去官网哪个页面 → 怎么用」一一对上，避免在官网里乱逛。

> [!summary] 速记版
> **四个入口，对应四种需求：**
> - 不知道图长什么样 → **示例**（Examples）
> - 不知道某个配置项怎么写 → **配置项手册**（Option）
> - 不知道某个方法 / 事件怎么调 → **API 手册**
> - 不知道概念或完整流程 → **使用手册**（Handbook）
>
> **学习闭环：** 示例里找模板 → 复制 `option` → 配置项手册查字段 → 换数据跑通 → 回真题验证。

## 一、先认清官网的 5 个入口

| 入口 | 地址 | 里面有什么 | 蓝桥杯什么时候用 |
| --- | --- | --- | --- |
| 使用手册 Handbook | [echarts.apache.org/handbook/zh](https://echarts.apache.org/handbook/zh/get-started) | 教程式文档：快速上手、引入方式、坐标系、数据集、样式、事件、动态数据 | 第一次学、补概念、看完整 HTML 模板 |
| 示例 Examples | [echarts.apache.org/examples/zh](https://echarts.apache.org/examples/zh/index.html) | 几百个可运行示例，按图表类型分类 | 找最接近题目的模板，复制 `option` |
| 配置项手册 Option | [echarts.apache.org/zh/option.html](https://echarts.apache.org/zh/option.html) | 所有 `option` 字段的字典，左侧树形导航 | 查某个字段的类型、默认值、可选值 |
| API 手册 | [echarts.apache.org/zh/api.html](https://echarts.apache.org/zh/api.html) | `init` / `setOption` / `on` / `resize` / `dispose` 等方法与事件 | 初始化、刷新、交互、销毁 |
| 主题与下载 | [主题编辑器](https://echarts.apache.org/zh/theme-builder.html) · [下载](https://echarts.apache.org/zh/download.html) | 主题 JSON、各版本 `echarts.js` | 需要换配色、本地引入文件时 |

> [!warning] 版本先对齐
> 官网首页当前主推 **ECharts 6.x**；蓝桥杯题目一般自带 `echarts.js`，版本以文件为准（常见 5.x）。
> 学习前先在控制台敲 `echarts.version` 看版本，再决定照哪套写法。官网手册里也有 [v5 升级指南](https://echarts.apache.org/handbook/zh/basics/release-note/v5-upgrade-guide) 和 [v6 升级指南](https://echarts.apache.org/handbook/zh/basics/release-note/v6-upgrade-guide)，遇到诡异差异先翻这里。

## 二、蓝桥杯考什么 → 去官网哪一页

| 大纲考点          | 具体要会                                                              | 官网对应页面                                                                                           |
| ------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **基础语法**      | `echarts.init(dom)` → 写 `option` → `setOption(option)` 三步         | [快速上手](https://echarts.apache.org/handbook/zh/get-started) · API `init` / `setOption`            |
| **绘制图表**      | 柱状图 / 折线图 / 饼图 / 散点图 / 雷达图 / 仪表盘；`xAxis`、`yAxis`、`series`         | [示例](https://echarts.apache.org/examples/zh/index.html) · 配置项手册 `series-*` · 手册「基础柱状图 / 折线图」     |
| **异步数据加载和更新** | `Promise` / `async-await` 拿到数据后再 `setOption`；`setInterval` 定时刷新   | 手册「[动态的异步数据](https://echarts.apache.org/handbook/zh/how-to/data/dynamic-data)」 · API `setOption` |
| **交互组件**      | `tooltip`、`legend`、`dataZoom`、`toolbox`                           | 配置项手册 `tooltip` / `legend` / `dataZoom` · 示例                                                     |
| **事件处理**      | `chart.on('click', params => …)` 取 `params.name` / `params.value` | 手册「[事件与行为](https://echarts.apache.org/handbook/zh/concepts/event)」 · API `on` / `off`            |

另外这些高频细节也都在上面几个页面里：

- **类目轴 vs 数值轴**：`xAxis.type` 的 `category` / `value` → 手册「[坐标系与坐标轴](https://echarts.apache.org/handbook/zh/concepts/axis)」
- **双 Y 轴**：`yAxis` 写成数组 + `series[].yAxisIndex` → 配置项手册 `yAxis`、`series.yAxisIndex`
- **堆叠 / 平滑 / 面积**：`series.stack`、`series.smooth`、`series.areaStyle` → 手册「堆叠柱状图」「平滑折线」
- **容器大小与自适应**：`grid.containLabel`、`chart.resize()` → 手册「[图表容器及大小](https://echarts.apache.org/handbook/zh/concepts/chart-size)」
- **数据集**：`dataset` 是另一种组织数据的方式，和 `series.data` 二选一 → 手册「[数据集](https://echarts.apache.org/handbook/zh/concepts/dataset)」

## 三、四个页面的正确打开方式

### 1. 示例页：当「模板库」用，不要当教程读

- 左侧按图表类型筛选（柱状图、折线图、饼图、散点图、雷达图、仪表盘、地图……），顶部有搜索框。
- 点开一个示例，能看到完整可运行的 `option`，并可在页面自带的编辑器里改数据、立刻看效果。
- **蓝桥杯用法**：
  1. 看题目截图，判断图表类型 + 轴的分工；
  2. 找最接近的示例，复制 `option`；
  3. 只保留 `title` / `tooltip` / `legend` / `xAxis` / `yAxis` / `series` 等必要项；
  4. 换成题目数据，跑通。

> [!tip] 示例里的「多余配置」要删
> 官网示例为了好看，常带 `toolbox`、`dataZoom`、`markLine`、`visualMap`、富文本标签等。蓝桥杯判题往往比对截图，**题目没要求的效果不要加**，否则可能对不上。反过来，如果题目要求了某个交互，再去示例里找同名组件照着配。

### 2. 配置项手册：当「字典」用，按需查

- 左侧树：`title` / `legend` / `grid` / `xAxis` / `yAxis` / `series` / `tooltip` / `dataZoom` / `visualMap` / `toolbox` / `dataset` ……
- 每个字段都标了：**类型、默认值、可选值、示例、生效版本**。
- 查法：
  - 轴的问题 → `xAxis.axisLabel` / `xAxis.axisTick` / `yAxis.position`
  - 柱子的问题 → `series-bar.barWidth` / `itemStyle` / `label`
  - 折线的问题 → `series-line.smooth` / `symbol` / `areaStyle`
  - 提示框 → `tooltip.trigger` / `formatter`
- 页面顶部可直接搜字段名；URL 支持锚点，例如 `option.html#series-bar.itemStyle`，查到好用的字段可以收藏成链接。

### 3. API 手册：查「方法」和「事件」

常考的只有这几个：

| API | 作用 | 蓝桥杯场景 |
| --- | --- | --- |
| `echarts.init(dom, theme?, opts?)` | 初始化实例 | 每个题的第一步 |
| `chart.setOption(option, notMerge?)` | 设置 / 更新配置 | 第二参数 `true` = 不合并、整体覆盖（异步刷新题） |
| `chart.on('click', handler)` | 绑定事件 | 点击柱子拿 `params.name` / `params.value` |
| `chart.resize()` | 重算尺寸 | 窗口缩放、容器尺寸变化 |
| `chart.dispose()` | 销毁实例 | 页面切换 / 重复初始化前清理 |
| `echarts.getInstanceByDom(dom)` | 取已有实例 | 避免重复 `init` 的警告 |

### 4. 使用手册：补概念，按章节跳读

推荐顺序（也是从易到难）：

1. [快速上手](https://echarts.apache.org/handbook/zh/get-started)：一个完整 HTML 页面，结构和蓝桥杯题目几乎一样；
2. [在项目中引入 ECharts](https://echarts.apache.org/handbook/zh/basics/import)：分清 `script` 标签引入和 npm 引入，对应题目里的本地 `echarts.js`；
3. 概念篇：[坐标系](https://echarts.apache.org/handbook/zh/concepts/axis) → [数据集](https://echarts.apache.org/handbook/zh/concepts/dataset) → [样式](https://echarts.apache.org/handbook/zh/concepts/style) → [图例](https://echarts.apache.org/handbook/zh/concepts/legend) → [事件与行为](https://echarts.apache.org/handbook/zh/concepts/event)；
4. 如何做：[基础柱状图](https://echarts.apache.org/handbook/zh/how-to/chart-types/bar/basic-bar)、[堆叠柱状图](https://echarts.apache.org/handbook/zh/how-to/chart-types/bar/stacked-bar)、[基础折线图](https://echarts.apache.org/handbook/zh/how-to/chart-types/line/basic-line)、[平滑折线](https://echarts.apache.org/handbook/zh/how-to/chart-types/line/smooth-line)、[基础饼图](https://echarts.apache.org/handbook/zh/how-to/chart-types/pie/basic-pie)、[基础散点图](https://echarts.apache.org/handbook/zh/how-to/chart-types/scatter/basic-scatter)、[动态的异步数据](https://echarts.apache.org/handbook/zh/how-to/data/dynamic-data)。

## 四、一套可复用的学习流程（30 分钟一个图）

1. **判类型**：看截图，确定是柱 / 线 / 饼 / 散点，以及轴的分工（==名字上 `category`，数字上 `value`==）。
2. **找模板**：示例页搜同类图，复制 `option`。
3. **删到最小**：只留 `title` + `tooltip` + `legend` + `xAxis` + `yAxis` + `series`。
4. **换数据**：把题目数据填进 `xAxis.data` 和 `series[].data`，跑通。
5. **加效果**：每加一个（双轴 / 堆叠 / 平滑 / 缩放），去配置项手册查一次字段，记进自己的笔记。
6. **默写**：关掉官网，手写一遍下面的最小模板。

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <script src="./echarts.js"></script>
  </head>
  <body>
    <div id="main" style="width: 600px; height: 400px"></div>
    <script>
      const myChart = echarts.init(document.getElementById('main'));

      const option = {
        title: { text: '标题' },
        tooltip: { trigger: 'axis' },
        legend: { data: ['系列名'] },
        xAxis: { type: 'category', data: ['A', 'B', 'C'] },
        yAxis: { type: 'value' },
        series: [{ name: '系列名', type: 'bar', data: [1, 2, 3] }],
      };

      myChart.setOption(option);
      window.addEventListener('resize', () => myChart.resize());
    </script>
  </body>
</html>
```

> [!note] 初始化三步就够
> `init` → `option` → `setOption`。其余一切（主题、事件、异步、双轴）都是在这三步上做加法。

## 五、把官网和题库对应起来

| 蓝桥云课真题 | 考点 | 先在官网看哪里 |
| --- | --- | --- |
| [学生信息统计（1843）](https://www.lanqiao.cn/problems/1843/learning/) | 补 `xAxis`、类目轴 | 手册「快速上手」的完整模板；示例「柱状图」；配置项 `xAxis.data` |
| [和手机相处的时光（2450）](https://www.lanqiao.cn/problems/2450/learning/) | `xAxis.type` / `yAxis.type` 写反 | 手册「[坐标系与坐标轴](https://echarts.apache.org/handbook/zh/concepts/axis)」；配置项 `xAxis.type` |
| [商品销量和销售额看板（2420）](https://www.lanqiao.cn/problems/2420/learning/) | 双 Y 轴 + 异步 + `setOption(option, true)` | 示例里搜「多 Y 轴」；手册「[动态的异步数据](https://echarts.apache.org/handbook/zh/how-to/data/dynamic-data)」；API `setOption` |

> [!tip] 刷题顺序
> 先按图表类型刷（柱 → 线 → 饼），再按能力刷（双轴 → 异步 → 事件）。ECharts 在蓝桥杯里属于难度较低的题型，**配置项熟练度 > 背代码**。

## 六、避坑清单

- **版本**：官网 6.x、题目 5.x，先 `echarts.version`；跨版本差异查升级指南。
- **数据组织方式**：示例常用 `dataset`，题目多用 `series.data`，别把两种混在一起。
- **引入方式**：示例可能是 CDN / npm / 本地 `echarts.js`，题目结构不能改，只抄 `option`。
- **判题约束**：只改题目允许的文件（如 `js/index.js`），不改文件名、目录、`id` / `class`。
- **重复 init**：`There is a chart instance already initialized on the dom.` 是警告不是报错，题目原代码若如此，别乱改。
- **数字字符串**：`toFixed()` 返回字符串，画图前 `Number()` 转一下更稳。
- **响应式**：容器尺寸变化后要 `resize()`，否则图表被裁切或留白。
- **搜索关键词用英文**：`barWidth`、`stacked`、`dual axis`、`notMerge` 命中率比中文高。

## 七、一周练法（可选）

| 天 | 官网任务（30 min） | 真题任务 |
| --- | --- | --- |
| 一 | 快速上手 + 示例「柱状图」 | 1843 学生信息统计 |
| 二 | 手册「坐标系」+ 示例「折线图」 | 2450 和手机相处的时光 |
| 三 | 饼图 / 环形图示例 | 自己改一版饼图 |
| 四 | 散点图 / 雷达图示例 | 记下 `radar.indicator` 写法 |
| 五 | 示例「多 Y 轴」+ 配置项 `yAxisIndex` | 2420 商品看板（只做双轴） |
| 六 | 手册「动态的异步数据」 | 2420 完整版 |
| 日 | 手册「事件与行为」 | 给任一图加 click 事件 + 复盘笔记 |

## 八、自检清单

- [ ] 能说出 5 个官网入口各自解决什么问题
- [ ] 不查资料能写出 `init` → `option` → `setOption`
- [ ] 能判断一个轴该用 `category` 还是 `value`
- [ ] 会写双 Y 轴（`yAxis` 数组 + `yAxisIndex`）
- [ ] 会用 `chart.on('click', params => …)` 取数据
- [ ] 知道 `setOption(option, true)` 的含义
- [ ] 知道什么时候要 `resize()`
- [ ] 能区分 `dataset` 和 `series.data`

## 参考链接

- [Apache ECharts 官网](https://echarts.apache.org/zh/index.html)
- [使用手册（Handbook）](https://echarts.apache.org/handbook/zh/get-started)
- [示例集（Examples）](https://echarts.apache.org/examples/zh/index.html)
- [配置项手册（Option）](https://echarts.apache.org/zh/option.html)
- [API 手册](https://echarts.apache.org/zh/api.html)
- [主题编辑器](https://echarts.apache.org/zh/theme-builder.html) · [下载](https://echarts.apache.org/zh/download.html)
