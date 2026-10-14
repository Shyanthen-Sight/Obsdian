

> 本文基于当前项目的实际代码编写，目标是帮助你理解这个车辆管理页面中各个 Vue 组件如何协作，以及 Vue 3 + TypeScript 中常见的核心知识。

项目入口：

- 页面组件：[Rent_page.vue](./src/components/Rent_page.vue)
- 组件目录：[src/components/car/](./src/components/car/)
- 路由文件：[router/index.ts](./src/router/index.ts)

---

## 一、这个页面解决了什么问题？

Car Merchant 是一个简单的车辆管理页面，目前包含这些功能：

1. 展示车辆列表。
2. 按预算筛选车辆。
3. 按车型筛选车辆。
4. 点击车辆卡片选中车辆。
5. 选中后显示高亮边框。
6. 添加车辆。
7. 为新车辆选择或拖拽上传图片。
8. 删除车辆前输入车辆编号进行验证。
9. 删除前进行二次确认。
10. 添加或删除成功后显示英文成功提示和动画。

这些功能如果全部写在一个文件中，会导致组件越来越长、状态越来越多、修改越来越困难。因此当前代码采用了==“父组件管理业务，子组件负责界面==”的拆分方式。

---

## 二、整体组件结构

当前结构如下：

```text
src/
├── App.vue
├── router/
│   └── index.ts
└── components/
    ├── Home_hero_page.vue
    ├── Nav_header.vue
    ├── Rent_page.vue
    └── car/
        ├── AddVehicleModal.vue
        ├── DeleteVehicleModal.vue
        ├── SuccessToast.vue
        ├── VehicleGrid.vue
        ├── VehicleToolbar.vue
        └── types.ts
```

在 `/rent_page` 路由中，页面关系可以理解为：

```text
App.vue
└── RouterView
    └── Rent_page.vue
        ├── VehicleToolbar.vue
        ├── VehicleGrid.vue
        ├── AddVehicleModal.vue
        ├── DeleteVehicleModal.vue
        └── SuccessToast.vue
```

其中：

| 文件                       | 主要职责                     |
| ------------------------ | ------------------------ |
| `Rent_page.vue`          | 页面容器、车辆数据、筛选计算、增删业务、状态协调 |
| `VehicleToolbar.vue`     | 筛选栏和预算输入                 |
| `VehicleGrid.vue`        | 车辆卡片列表和选中事件              |
| `AddVehicleModal.vue`    | 添加车辆弹窗及表单                |
| `DeleteVehicleModal.vue` | 删除编号验证和二次确认              |
| `SuccessToast.vue`       | 成功提示和过渡动画                |
| `types.ts`               | 车辆相关 TypeScript 类型       |

---

## 三、最重要的设计原则：状态放在父组件

当前设计遵循一个非常重要的原则：

> <mark style="background:#40a9ff">谁需要协调多个组件，谁就负责保存公共状态</mark>。

例如：

- `VehicleGrid` 需要知道当前选中哪辆车。
- 删除按钮也需要知道当前选中哪辆车。
- 删除弹窗需要显示被删除车辆的信息。
- 添加成功后，车辆列表需要刷新。
- 成功提示需要由添加和删除两个功能共同触发。

所以这些状态放在父组件 `Rent_page.vue` 中：

```ts
const cars = ref<Car[]>(initialCars);
const selectedCarId = ref<string | null>(null);
const isAddModalOpen = ref(false);
const isDeleteModalOpen = ref(false);
const deleteTargetCarId = ref<string | null>(null);
const successMessage = ref('');
```

子组件不直接修改父组件的数组，也不直接操作父组件的状态，而是：

1. 父组件通过 `props` 把数据传给子组件。
2. 子组件通过 `emit` 把用户操作通知给父组件。
3. 父组件执行真正的业务修改。
4. 修改后的数据再次通过 `props` 传回子组件。

这就是 Vue 中常见的单向数据流：

```text
父组件 props -> 子组件
子组件 emit  -> 父组件
```

---

## 四、`Rent_page.vue`：页面容器和业务中心

文件：[Rent_page.vue](./src/components/Rent_page.vue)

### 4.1 `script setup`

组件使用 Vue 3 的 `<script setup>`：

```vue
<script setup lang="ts">
import { computed, ref } from 'vue';
</script>
```

它有几个特点：

1. 不需要手动写 `export default`。
2. 在脚本中声明的变量，可以直接在模板中使用。
3. 导入的组件可以直接在模板中使用。
4. 适合组合式 API（Composition API）。
5. 配合 TypeScript 时类型推导更自然。

例如：

```ts
import VehicleGrid from './car/VehicleGrid.vue';
```

导入后可以直接在模板中写：

```vue
<VehicleGrid />
```

---

### 4.2 `ref`：声明响应式状态

```ts
const selectedCarId = ref<string | null>(null);
```

这里的含义是：

- `selectedCarId` 是一个响应式变量。
- 初始值是 `null`，表示还没有选中车辆。
- 它的类型是 `string | null`。
- 在 `<script setup>` 中修改它需要使用 `.value`。
- 在模板中 Vue 会自动拆包，不需要写 `.value`。

脚本中：

```ts
selectedCarId.value = car.id;
```

模板中：

```vue
:disabled="selectedCarId === null"
```

这是 Vue 的一个重要特点：

```text
script 中：ref.value
template 中：直接使用变量
```

常见的 `ref` 状态：

```ts
const minBudget = ref(0);
const maxBudget = ref(0);
const selectedTypes = ref<CarType[]>([]);
const isFilterOpen = ref(true);
const isAddModalOpen = ref(false);
const isDeleteModalOpen = ref(false);
const successMessage = ref('');
```

它们分别表示：

| 状态 | 含义 |
|---|---|
| `minBudget` | 最低预算 |
| `maxBudget` | 最高预算 |
| `selectedTypes` | 被选中的车型数组 |
| `isFilterOpen` | 筛选区域是否展开 |
| `isAddModalOpen` | 添加弹窗是否显示 |
| `isDeleteModalOpen` | 删除弹窗是否显示 |
| `successMessage` | 成功提示文字 |

---

### 4.3 `computed`：从已有状态推导新状态

`computed` 适合表示“可以由现有数据计算出来的值”。

当前页面有三个典型的计算属性。

#### 当前选中的车辆

```ts
const selectedCar = computed(() =>
  cars.value.find((car) => car.id === selectedCarId.value),
);
```

它不会额外保存一份车辆对象，而是根据 `selectedCarId` 从 `cars` 中查找。

这样可以避免两个状态不同步：

```text
cars + selectedCarId -> selectedCar
```

#### 当前要删除的车辆

```ts
const deleteTargetCar = computed(() =>
  cars.value.find((car) => car.id === deleteTargetCarId.value),
);
```

删除流程使用单独的 `deleteTargetCarId`，而不是始终依赖当前选中车辆。这样可以避免：

1. 打开删除弹窗后，选中状态被其它操作改变。
2. 弹窗显示的车辆和最终删除的车辆不一致。
3. 删除过程中出现“误删当前另一辆车”的问题。

#### 筛选后的车辆

```ts
const filteredCars = computed(() =>
  cars.value.filter((car) => {
    const matchesType =
      selectedTypes.value.length === 0 ||
      selectedTypes.value.includes(car.type);
    const matchesMinBudget =
      minBudget.value <= 0 || car.dailyPrice >= minBudget.value;
    const matchesMaxBudget =
      maxBudget.value <= 0 || car.dailyPrice <= maxBudget.value;

    return matchesType && matchesMinBudget && matchesMaxBudget;
  }),
);
```

筛选规则是：

- 没有选车型：所有车型都匹配。
- 选了车型：车辆类型必须出现在 `selectedTypes` 中。
- 最低预算小于等于 0：不限制最低价格。
- 最高预算小于等于 0：不限制最高价格。
- 所有条件都满足，车辆才会显示。

`computed` 的好处是依赖变化时自动重新计算：

```text
minBudget / maxBudget / selectedTypes / cars
        ↓
filteredCars
        ↓
VehicleGrid
```

---

## 五、`types.ts`：统一数据类型

文件：[types.ts](./src/components/car/types.ts)

### 5.1 车型联合类型

```ts
export type CarType =
  | 'MPV'
  | 'SUV'
  | 'Sedan'
  | 'Pickup'
  | 'Sports';
```

这不是普通的 `string`，而是只允许这五个值：

```ts
const type: CarType = 'SUV';       // 正确
const type: CarType = 'Motorbike'; // 类型错误
```

这样可以防止拼写错误和无效车型进入系统。

### 5.2 `Car` 接口

```ts
export interface Car {
  id: string;
  fileName: string;
  name: string;
  type: CarType;
  dailyPrice: number;
  mileage: number;
  stock: number;
  image: string;
}
```

`Car` 描述完整车辆对象。

### 5.3 `NewCarInput` 接口

```ts
export interface NewCarInput {
  name: string;
  type: CarType;
  dailyPrice: number;
  mileage: number;
  stock: number;
  image: string;
}
```

添加车辆时，用户只需要填写这些信息，`id` 和 `fileName` 由父组件生成，因此没有放入 `NewCarInput`。

这是一个常见设计：

```text
完整实体 Car
        =
系统生成字段 + 用户输入字段
```

---

## 六、`VehicleToolbar.vue`：筛选工具栏

文件：[VehicleToolbar.vue](./src/components/car/VehicleToolbar.vue)

### 6.1 接收父组件数据：`defineProps`

```ts
defineProps<{
  minBudget: number;
  maxBudget: number;
  selectedTypes: CarType[];
  isFilterOpen: boolean;
  activeFilterCount: number;
}>();
```

子组件接收五个只读输入：

| Prop | 类型 | 作用 |
|---|---|---|
| `minBudget` | `number` | 最低预算 |
| `maxBudget` | `number` | 最高预算 |
| `selectedTypes` | `CarType[]` | 选中的车型 |
| `isFilterOpen` | `boolean` | 筛选面板是否展开 |
| `activeFilterCount` | `number` | 当前筛选数量 |

父组件中这样传递：

```vue
<VehicleToolbar
  v-model:min-budget="minBudget"
  v-model:max-budget="maxBudget"
  :selected-types="selectedTypes"
  :is-filter-open="isFilterOpen"
  :active-filter-count="activeFilterCount"
/>
```

注意命名转换：

```text
父组件属性：min-budget
子组件脚本：minBudget
```

Vue 模板中推荐使用短横线命名，脚本中使用小驼峰命名。

---

### 6.2 子组件向父组件发送事件：`defineEmits`

```ts
const emit = defineEmits<{
  'update:minBudget': [value: number];
  'update:maxBudget': [value: number];
  'update:isFilterOpen': [value: boolean];
  toggleType: [type: CarType];
  resetFilters: [];
}>();
```

事件可以分为两类。

#### 更新类事件

```ts
'update:minBudget': [value: number]
```

表示事件名是 `update:minBudget`，并且必须携带一个数字参数。

#### 动作类事件

```ts
toggleType: [type: CarType];
resetFilters: [];
```

表示：

- `toggleType` 需要传一个车型。
- `resetFilters` 不需要参数。

子组件触发事件：

```vue
@click="emit('toggleType', type)"
```

父组件监听事件：

```vue
@toggle-type="toggleType"
@reset-filters="resetFilters"
```

Vue 会自动把事件名从 `toggleType` 转换为模板中的 `toggle-type`。

---

### 6.3 多个 `v-model`

父组件使用：

```vue
<VehicleToolbar
  v-model:min-budget="minBudget"
  v-model:max-budget="maxBudget"
/>
```

这相当于：

```vue
<VehicleToolbar
  :min-budget="minBudget"
  @update:minBudget="minBudget = $event"
  :max-budget="maxBudget"
  @update:maxBudget="maxBudget = $event"
/>
```

`v-model:xxx` 的规则是：

```text
v-model:foo="bar"
等价于
:foo="bar" @update:foo="bar = $event"
```

这是 Vue 3 中实现多字段双向绑定的标准方式。

---

## 七、`VehicleGrid.vue`：车辆列表

文件：[VehicleGrid.vue](./src/components/car/VehicleGrid.vue)

### 7.1 接收列表和选中状态

```ts
defineProps<{
  cars: Car[];
  totalCars: number;
  selectedCarId: string | null;
}>();
```

这里的 `cars` 是已经筛选后的车辆，`totalCars` 是筛选前的总数。

模板中：

```vue
<p>{{ cars.length }} of {{ totalCars }} cars</p>
```

例如：

```text
12 of 43 cars
```

表示当前显示 12 辆，总车辆数量是 43 辆。

---

### 7.2 `v-for` 和 `:key`

```vue
<article
  v-for="car in cars"
  :key="car.id"
>
```

`v-for` 用来循环渲染车辆。

`:key` 非常重要，它帮助 Vue 识别每个列表项的唯一身份。这里使用车辆编号：

```vue
:key="car.id"
```

不建议使用数组下标：

```vue
<!-- 不推荐 -->
:key="index"
```

因为删除或筛选时，数组下标可能变化，Vue 可能错误复用 DOM。

---

### 7.3 选中高亮

```vue
:class="{ selected: selectedCarId === car.id }"
```

含义是：

- 如果当前车辆 ID 等于选中 ID，就添加 `selected` 类。
- 否则不添加。

CSS 中：

```css
.car_card.selected {
  border-color: var(--accent);
  background: #fffaf3;
  outline: 2px solid var(--accent);
}
```

点击车辆时：

```vue
@click="emit('select', car.id)"
```

父组件接收：

```vue
@select="selectedCarId = $event"
```

完整链路：

```text
用户点击卡片
    ↓
VehicleGrid emit('select', car.id)
    ↓
Rent_page selectedCarId = $event
    ↓
selectedCarId 变化
    ↓
:class 重新计算
    ↓
出现高亮边框
```

---

### 7.4 键盘可访问性

车辆卡片增加了：

```vue
tabindex="0"
@keydown.enter="emit('select', car.id)"
```

作用是：

- `tabindex="0"`：允许键盘 Tab 聚焦。
- `Enter`：聚焦后可以按回车选中。
- `:aria-selected`：让辅助技术知道当前是否被选中。

这比只支持鼠标点击更完整。

---

## 八、`AddVehicleModal.vue`：添加车辆

文件：[AddVehicleModal.vue](./src/components/car/AddVehicleModal.vue)

### 8.1 为什么表单状态放在弹窗内部？

添加表单中的这些字段：

```ts
const name = ref('');
const type = ref<CarType>('MPV');
const dailyPrice = ref(100);
const mileage = ref(0);
const stock = ref(1);
const image = ref('');
```

只在添加弹窗内部使用，因此放在 `AddVehicleModal.vue` 更合适。

父组件只关心最终提交的数据：

```ts
submit: [vehicle: NewCarInput];
```

这样父组件不需要知道表单里有多少输入框。

这叫做封装：

> 组件内部管理自己的临时表单状态，组件外部只接收最终结果。

---

### 8.2 表单提交

模板：

```vue
<form @submit.prevent="submit">
```

`.prevent` 会阻止浏览器默认提交行为，避免页面刷新。

提交函数：

```ts
const submit = () => {
  const trimmedName = name.value.trim();
  if (
    !trimmedName ||
    dailyPrice.value < 0 ||
    mileage.value < 0 ||
    stock.value < 0
  ) {
    return;
  }

  emit('submit', {
    name: trimmedName,
    type: type.value,
    dailyPrice: dailyPrice.value,
    mileage: mileage.value,
    stock: stock.value,
    image: image.value,
  });

  close();
};
```

这里做了三件事：

1. 去掉车辆名称首尾空格。
2. 检查必填字段和非负数。
3. 将表单数据通过 `submit` 事件交给父组件。

父组件接收：

```ts
const submitNewCar = (input: NewCarInput) => {
  const newCar: Car = {
    id: nextId,
    fileName: 'new-car.png',
    ...input,
  };

  cars.value.push(newCar);
};
```

父组件负责补充系统字段 `id` 和 `fileName`。

---

### 8.3 文件上传和拖拽

图片选择：

```vue
<input
  type="file"
  accept="image/*"
  @change="setImage(($event.target as HTMLInputElement).files?.[0])"
/>
```

`accept="image/*"` 表示文件选择器优先选择图片。

读取图片：

```ts
const setImage = (file: File | undefined) => {
  if (!file || !file.type.startsWith('image/')) return;

  image.value = URL.createObjectURL(file);
  imageName.value = file.name;
};
```

`URL.createObjectURL(file)` 会为本地文件创建一个临时 URL，可以直接给 `<img>` 使用：

```vue
<img v-if="image" :src="image" />
```

需要注意：

- 这个 URL 是临时的。
- 它不等于上传到服务器。
- 如果项目以后接入后端，需要使用 `FormData` 上传文件。
- 长时间运行的应用中，替换图片时可以调用 `URL.revokeObjectURL()` 释放旧 URL。

拖拽上传使用：

```vue
@dragenter.prevent
@dragover.prevent
@dragleave.prevent
@drop.prevent
```

`.prevent` 可以阻止浏览器把文件直接打开。

---

## 九、`DeleteVehicleModal.vue`：删除确认流程

文件：[DeleteVehicleModal.vue](./src/components/car/DeleteVehicleModal.vue)

删除组件内部有三个状态：

```ts
const step = ref<1 | 2>(1);
const code = ref('');
const error = ref('');
```

### 9.1 删除流程

```text
父组件选中车辆
    ↓
点击删除按钮
    ↓
父组件记录 deleteTargetCarId
    ↓
打开 DeleteVehicleModal
    ↓
用户输入车辆编号
    ↓
verifyCode()
    ↓
编号正确：step = 2
编号错误：显示 error
    ↓
用户确认删除
    ↓
emit('confirm', car.id)
    ↓
父组件真正从 cars 中删除
```

### 9.2 `watch`：监听弹窗重新打开

```ts
watch(() => props.visible, (visible) => {
  if (visible) {
    step.value = 1;
    code.value = '';
    error.value = '';
  }
});
```

每次弹窗从关闭变为打开时，都重置内部状态。

如果没有这段代码，可能出现：

1. 上一次输入的编号仍然保留。
2. 上一次的错误信息还显示着。
3. 弹窗重新打开时直接处于第二步。

`watch` 适合监听状态变化并执行副作用。

---

### 9.3 为什么子组件只发出 ID？

```ts
confirm: [carId: string];
```

子组件确认删除时只发出车辆 ID：

```ts
emit('confirm', props.car.id);
```

真正删除仍然由父组件完成：

```ts
const deleteSelectedCar = (targetCarId: string) => {
  const selectedIndex = cars.value.findIndex(
    (car) => car.id === targetCarId,
  );

  if (selectedIndex === -1) return;
  cars.value.splice(selectedIndex, 1);
};
```

这是职责分离：

- 弹窗负责验证和确认。
- 父组件负责修改车辆数据。

---

## 十、`SuccessToast.vue`：成功提示和动画

文件：[SuccessToast.vue](./src/components/car/SuccessToast.vue)

组件只接收一个属性：

```ts
defineProps<{
  message: string;
}>();
```

模板：

```vue
<Transition name="success-toast">
  <div v-if="message" class="success_message">
    ...
  </div>
</Transition>
```

只要 `message` 不是空字符串，提示就会出现：

```text
message = ''
    -> 不渲染

message = 'Vehicle added successfully'
    -> 渲染并执行进入动画
```

当父组件把 `message` 清空时，Vue 执行离开动画。

### 10.1 Vue Transition 命名规则

因为写了：

```vue
<Transition name="success-toast">
```

Vue 会寻找这些 CSS 类：

```css
.success-toast-enter-active
.success-toast-enter-from
.success-toast-leave-active
.success-toast-leave-to
```

进入动画：

```css
.success-toast-enter-from {
  opacity: 0;
  transform: translate(-50%, -1rem) scale(0.92);
}
```

最终状态由普通 `.success_message` 提供：

```css
.success_message {
  opacity: 1;
  transform: translateX(-50%);
}
```

因此效果是：

```text
透明、向上、略微缩小
        ↓ transition
完全显示、回到正常位置
```

---

## 十一、图片为什么使用 `import.meta.glob`

父组件中：

```ts
const carImageModules = import.meta.glob(
  '../assets/image/CarClass/**/*.png',
  {
    eager: true,
    query: '?url',
    import: 'default',
  },
) as Record<string, string>;
```

这是 Vite 提供的批量导入功能。

含义：

```text
查找 CarClass 目录及子目录下的所有 PNG 图片
```

`eager: true` 表示构建时立即加载，不使用懒加载函数。

`query: '?url'` 和 `import: 'default'` 让返回结果直接是图片 URL。

最终得到类似这样的对象：

```ts
{
  '../assets/image/CarClass/MPV/zeekr 009.png': '/assets/zeekr-009.hash.png',
  '../assets/image/CarClass/SUV/Benz.png': '/assets/Benz.hash.png'
}
```

生成车辆数据时拼接路径：

```ts
image:
  carImageModules[
    `../assets/image/CarClass/${
      car.type === 'Sports' ? 'SportsCar' : car.type
    }/${car.fileName}`
  ] ?? ''
```

这里有一个重要细节：

```ts
type: 'Sports'
```

数据中的类型叫 `Sports`，但文件夹叫 `SportsCar`，因此需要单独转换。

如果文件名或文件夹名不完全匹配，图片就会变成空字符串，页面会显示：

```vue
<div v-else class="no_car_image">No vehicle image</div>
```

中文文件名尤其要注意编码和精确匹配。

---

## 十二、完整操作链路：添加车辆

### 12.1 用户操作

用户点击左侧添加按钮：

```vue
<button @click="addCar">
```

父组件执行：

```ts
const addCar = () => {
  isAddModalOpen.value = true;
};
```

模板根据状态显示：

```vue
<AddVehicleModal
  :visible="isAddModalOpen"
  @close="closeAddModal"
  @submit="submitNewCar"
/>
```

### 12.2 子组件提交

用户填写表单并提交，子组件发出：

```ts
emit('submit', {
  name,
  type,
  dailyPrice,
  mileage,
  stock,
  image,
});
```

### 12.3 父组件创建完整对象

```ts
const newCar: Car = {
  id: `CAR-${String(nextNumber).padStart(3, '0')}`,
  fileName: 'new-car.png',
  ...input,
};
```

然后：

```ts
cars.value.push(newCar);
selectedCarId.value = newCar.id;
showSuccessMessage(`Vehicle added successfully: ${newCar.name}`);
```

最终结果：

```text
cars 改变
    ↓
filteredCars 重新计算
    ↓
VehicleGrid 收到新数组
    ↓
新车辆出现在列表
    ↓
新车辆自动被选中
    ↓
SuccessToast 显示成功提示
```

---

## 十三、完整操作链路：删除车辆

### 13.1 删除按钮为什么有时禁用？

```vue
:disabled="selectedCarId === null"
```

没有选中车辆时：

```text
selectedCarId === null
```

删除按钮禁用。

点击车辆后：

```vue
@click="emit('select', car.id)"
```

父组件设置：

```ts
selectedCarId.value = carId;
```

此时删除按钮解除禁用。

### 13.2 打开删除弹窗

```ts
const openDeleteModal = () => {
  if (!selectedCar.value) return;
  deleteTargetCarId.value = selectedCar.value.id;
  isDeleteModalOpen.value = true;
};
```

这里保存的是删除目标 ID，而不是只保存一个临时对象。

### 13.3 验证编号

```ts
if (code.value.trim().toUpperCase() !== props.car.id) {
  error.value = 'The vehicle code does not match the selected vehicle.';
  return;
}
```

`trim()` 去除前后空格，`toUpperCase()` 统一大小写。

例如用户输入：

```text
 car-001
```

会被转换成：

```text
CAR-001
```

### 13.4 执行删除

编号验证通过后，子组件发出：

```ts
emit('confirm', props.car.id);
```

父组件从数组中找到对应位置：

```ts
const selectedIndex = cars.value.findIndex(
  (car) => car.id === targetCarId,
);
```

然后删除：

```ts
cars.value.splice(selectedIndex, 1);
```

如果删除的正是当前选中车辆：

```ts
if (selectedCarId.value === targetCarId) {
  selectedCarId.value = null;
}
```

这样删除按钮会重新变为禁用状态。

---

## 十四、父子组件通信总结表

| 场景 | 父组件传给子组件 | 子组件发给父组件 |
|---|---|---|
| 筛选栏 | 预算、选中类型、筛选数量 | 更新预算、切换类型、重置 |
| 车辆列表 | 车辆数组、总数、选中 ID | 选中某辆车 |
| 添加弹窗 | 是否显示 | 关闭、提交新车辆 |
| 删除弹窗 | 是否显示、删除目标车辆 | 关闭、确认删除 ID |
| 成功提示 | 提示文字 | 无 |

可以用一句话记忆：

> Props 向下传数据，emit 向上报告事件。

---

## 十五、CSS 变量为什么子组件可以使用？

父组件根节点定义了变量：

```css
#rent_page {
  --ink: #172334;
  --muted: #728096;
  --surface: #f7f8fa;
  --panel: #ffffff;
  --line: #dfe4eb;
  --accent: #b58b52;
  --accent-dark: #8f693a;
  --accent-soft: #f4ecdf;
  --navy-soft: #edf1f5;
}
```

子组件中也使用：

```css
background: var(--surface);
color: var(--ink);
border-color: var(--line);
```

原因是 CSS 自定义属性具有继承性。只要子组件渲染在 `#rent_page` 内部，就可以继承这些变量。

这比在每个子组件中重复写颜色更好：

```text
修改一个变量
    ↓
整个车辆页面的主题同步变化
```

如果将来使用 Vue 的 `<Teleport>` 把弹窗挂到 `body`，那么弹窗可能不再继承 `#rent_page` 上的变量，需要把主题变量放到 `:root` 或 `body` 上。

---

## 十六、为什么使用 `scoped` 样式？

组件中使用：

```vue
<style scoped>
</style>
```

Vue 会为当前组件的元素添加特殊属性，并把 CSS 选择器限制在当前组件范围内。

好处：

1. 防止 `.car_card` 污染其它页面。
2. 防止 `.modal_title` 和其它组件重名冲突。
3. 组件可以拥有相对独立的样式。

需要注意：

- `scoped` 不代表 CSS 变量不能继承。
- `scoped` 不会阻止父组件传下来的 CSS 自定义属性。
- 如果想修改子组件内部深层元素，可以使用 `:deep()`，但应谨慎使用。

---

## 十七、路由和页面加载

文件：[router/index.ts](./src/router/index.ts)

路由配置：

```ts
const routes = [
  {
    path: '/',
    name: 'Home_page',
    component: Home_hero_page,
  },
  {
    path: '/rent_page',
    name: 'Rent_page',
    component: Rent_page,
  },
];
```

当浏览器访问：

```text
/rent_page
```

`RouterView` 会渲染 `Rent_page.vue`。

在 `App.vue` 中：

```vue
<Nav_header />
<router-view />
```

`router-view` 是路由页面的占位区域。

整体流程：

```text
浏览器访问 /rent_page
        ↓
Vue Router 匹配路由
        ↓
RouterView 渲染 Rent_page.vue
        ↓
Rent_page 渲染车辆管理子组件
```

---

## 十八、当前架构的优点

### 18.1 职责更清晰

每个组件只处理一类功能：

```text
Toolbar       -> 筛选
Grid          -> 列表
AddModal      -> 添加
DeleteModal   -> 删除
SuccessToast  -> 提示
```

### 18.2 父组件掌握数据源

只有 `Rent_page.vue` 修改 `cars`，不容易出现多个组件同时修改同一份数据的问题。

### 18.3 子组件可复用

例如 `SuccessToast.vue` 不一定只能用于车辆页面，也可以用于：

- 用户新增成功
- 订单保存成功
- 表单提交成功

### 18.4 类型安全

通过 `CarType`、`Car`、`NewCarInput`，编辑器可以提前发现很多错误。

### 18.5 更容易定位问题

如果筛选出错，先看 `VehicleToolbar` 和父组件的 `filteredCars`。

如果高亮出错，先看 `VehicleGrid` 的 `selectedCarId`。

如果删除出错，先看 `DeleteVehicleModal` 的验证流程和父组件的删除逻辑。

---

## 十九、学习时建议重点练习的改动

### 练习 1：给车辆列表增加品牌筛选

步骤：

1. 在 `Car` 中增加 `brand`。
2. 在 `VehicleToolbar` 中添加品牌按钮。
3. 在 `Rent_page.vue` 中增加 `selectedBrands`。
4. 在 `filteredCars` 中增加品牌判断。

### 练习 2：增加排序

例如增加：

```ts
const sortBy = ref<'priceAsc' | 'priceDesc' | 'mileage'>('priceAsc');
```

然后在 `filteredCars` 的基础上继续计算排序结果。

推荐拆成两个计算属性：

```ts
const filteredCars = computed(() => ...);
const displayedCars = computed(() => sortCars(filteredCars.value));
```

### 练习 3：把车辆数据放到 Pinia

当前数据放在 `Rent_page.vue`：

```ts
const cars = ref<Car[]>(initialCars);
```

如果多个页面都需要车辆数据，可以提取到 Pinia Store：

```text
stores/
└── cars.ts
```

这样首页、租车页、后台管理页都可以共享车辆数据。

### 练习 4：将数据保存到后端

当前添加和删除只修改内存：

```ts
cars.value.push(newCar);
cars.value.splice(selectedIndex, 1);
```

刷新页面后数据会恢复初始值。

接入后端后，应改成：

```text
提交 API
    ↓
服务器保存
    ↓
请求成功
    ↓
更新本地状态
    ↓
显示成功提示
```

### 练习 5：完善表单错误提示

当前添加表单通过 `required` 和简单的数字判断完成校验。可以继续增加：

- 车辆名称长度限制。
- 价格必须是整数。
- 库存不能超过指定上限。
- 文件大小限制。
- 文件格式限制。
- 每个字段下方显示具体错误信息。

---

## 二十、常见问题和排查方法

### 问题 1：删除按钮一直禁用

检查：

```ts
const selectedCarId = ref<string | null>(null);
```

以及车辆卡片是否触发：

```vue
@click="emit('select', car.id)"
```

再检查父组件是否监听：

```vue
@select="selectedCarId = $event"
```

三者缺一不可。

### 问题 2：选中后没有高亮

检查：

```vue
:class="{ selected: selectedCarId === car.id }"
```

以及 CSS：

```css
.car_card.selected {
  outline: 2px solid var(--accent);
}
```

### 问题 3：图片少了

检查文件名是否完全一致：

```text
代码中的 fileName
实际磁盘文件名
```

尤其注意：

- 中文字符。
- 空格。
- 大小写。
- 文件夹名称。
- `Sports` 和 `SportsCar` 的特殊映射。

### 问题 4：子组件无法修改父组件数据

这是正常的。Props 是只读的。

错误做法：

```ts
props.cars.push(newCar);
```

推荐做法：

```ts
emit('submit', newCarInput);
```

让父组件修改自己的状态。

### 问题 5：成功提示不显示

检查：

```vue
<SuccessToast :message="successMessage" />
```

以及触发：

```ts
showSuccessMessage('Vehicle added successfully');
```

还要确认 `successMessage` 没有在显示前立即被清空。

---

## 二十一、建议的阅读顺序

如果你是按照学习路线阅读，推荐这样看：

### 第一步：看类型

先看 [types.ts](./src/components/car/types.ts)，理解一辆车有哪些属性。

### 第二步：看父组件

阅读 [Rent_page.vue](./src/components/Rent_page.vue) 的：

1. `ref`
2. `computed`
3. `submitNewCar`
4. `deleteSelectedCar`
5. 模板中的组件组合

### 第三步：看列表

阅读 [VehicleGrid.vue](./src/components/car/VehicleGrid.vue)，理解：

- `props`
- `emit`
- `v-for`
- `:key`
- 动态 class

### 第四步：看筛选

阅读 [VehicleToolbar.vue](./src/components/car/VehicleToolbar.vue)，理解：

- 多个 `v-model`
- `update:xxx`
- 表单输入事件

### 第五步：看添加和删除弹窗

阅读：

- [AddVehicleModal.vue](./src/components/car/AddVehicleModal.vue)
- [DeleteVehicleModal.vue](./src/components/car/DeleteVehicleModal.vue)

重点理解：

- 子组件内部状态。
- `defineEmits`。
- `watch`。
- 表单提交。
- 两步删除确认。

### 第六步：看动画

最后阅读 [SuccessToast.vue](./src/components/car/SuccessToast.vue)，理解 Vue 的 `<Transition>`。

---

## 二十二、最终总结

当前项目体现了 Vue 组件化开发的几个核心思想：

```text
数据集中管理
    +
功能拆成组件
    +
Props 向下传递数据
    +
Emit 向上通知事件
    +
Computed 推导显示数据
    +
Ref 管理响应式状态
    +
TypeScript 约束数据结构
    +
Transition 提供交互动画
```

最重要的页面数据流可以简化为：

```text
Rent_page.vue
  ├── cars
  ├── selectedCarId
  ├── filters
  └── modal states
        │
        ├── props -> VehicleToolbar
        ├── props -> VehicleGrid
        ├── props -> AddVehicleModal
        ├── props -> DeleteVehicleModal
        └── props -> SuccessToast

子组件操作
        │
        └── emit -> Rent_page.vue
```

当你能够解释下面这句话时，就基本理解了这个项目的架构：

> `Rent_page.vue` 持有车辆和页面状态，子组件只负责展示局部界面、收集用户操作，并通过事件把结果交还给父组件；父组件更新响应式数据后，Vue 自动重新渲染相关组件。
