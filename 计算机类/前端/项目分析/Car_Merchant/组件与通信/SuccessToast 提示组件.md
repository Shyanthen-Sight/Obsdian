# SuccessToast 提示组件

> [!abstract] 一句话
> `SuccessToast` 是一个极简的提示组件：父组件把 ==提示文字 `message`== 通过 props 传进来，子组件用 `v-if` 决定显示与否，再用 `<Transition>` 给出现/消失加上动画；父组件则用定时器在 2.5 秒后把文字清空。

---

## 一、SuccessToast 的实现

父组件：

```vue
<SuccessToast :message="successMessage" />
```

子组件：

```ts
defineProps<{
  message: string;
}>();
```

模板：

```vue
<Transition name="success-toast">
  <div
    v-if="message"
    class="success_message"
    role="status"
    aria-live="polite"
  >
    <span class="success_icon">✓</span>
    <span>{{ message }}</span>
  </div>
</Transition>
```

### 1.1 `v-if`

只有 `message` 非空时，提示框才会存在：

```text
message = ''              → 不渲染
message = 'Vehicle added' → 渲染
```

### 1.2 `<Transition>`

```vue
<Transition name="success-toast">
```

Vue 会根据 `name` 自动添加过渡类：

```text
success-toast-enter-active
success-toast-enter-from
success-toast-leave-active
success-toast-leave-to
```

因此提示框出现和消失时会有淡入淡出和位移动画。

### 1.3 定时隐藏提示

父组件：

```ts
const showSuccessMessage = (message: string) => {
  successMessage.value = message;

  if (successMessageTimer !== undefined) {
    window.clearTimeout(successMessageTimer);
  }

  successMessageTimer = window.setTimeout(() => {
    successMessage.value = '';
    successMessageTimer = undefined;
  }, 2500);
};
```

> [!tip] 先清旧定时器，再设新定时器
> 如果连续进行多次操作，会先清除旧定时器，再设置新定时器，避免多个定时器互相干扰。

---

返回目录 [[Car Merchant 项目完整详解]] ｜ 上一篇 [[组件关系与父子通信]] ｜ 下一篇 → [[租车页状态与数据]]
