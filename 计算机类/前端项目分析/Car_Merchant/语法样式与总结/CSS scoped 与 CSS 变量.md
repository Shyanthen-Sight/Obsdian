# CSS scoped 与 CSS 变量

> [!abstract] 一句话
> `<style scoped>` 让样式只作用于当前组件（Vue 会插入 `data-v-xxxxxx` 属性做隔离）；项目又在 `Rent_page.vue` 的根节点上定义了一组 ==CSS 自定义变量（主题色）==，借由 CSS 变量的继承特性，让子组件直接 `var(--line)` 取用，避免到处重复写颜色。

---

## 一、CSS scoped 和 CSS 变量

组件中的：

```vue
<style scoped>
```

表示样式只作用于当前组件。

Vue 会为元素添加类似的内部属性：

```html
<div data-v-xxxxxx></div>
```

同时将 CSS 选择器转换为带属性选择器的形式，避免不同组件之间的类名冲突。

### 1.1 CSS 自定义变量

`Rent_page.vue` 中定义：

```css
#rent_page {
  --ink: #172334;
  --muted: #728096;
  --surface: #f7f8fa;
  --panel: #ffffff;
  --line: #dfe4eb;
  --accent: #b58b52;
}
```

子组件中使用：

```css
.car_card {
  border-color: var(--line);
  background: var(--panel);
}
```

CSS 自定义属性会沿 DOM 父子关系继承，因此租车页下的子组件可以使用这些主题变量。

这比在每个组件中重复写颜色更容易维护。

### 1.2 父组件样式的职责

当前父组件只保留：

- 整体页面布局
- 左侧添加/删除工具栏
- 主内容区布局
- 主题变量

车辆网格样式由 `VehicleGrid.vue` 管理，筛选栏样式由 `VehicleToolbar.vue` 管理，弹窗样式由对应弹窗组件管理。

这样可以避免所有样式都堆积到 `Rent_page.vue` 中。

---

返回目录 [[Car Merchant 项目完整详解]] ｜ 上一篇 [[模板语法详解]] ｜ 下一篇 → [[事件与数据流总图]]
