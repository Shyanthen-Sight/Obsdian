# class

> [!abstract] 一句话定义
> `class` 在 TypeScript 里**一身两职**：作为**值**它能 `new` 出实例，作为**类型**它描述"实例长什么样"——==它是唯一同时活跃在值与类型两个世界的声明==。

---

## 一、基本用法

```ts
class Point {
  x: number                 // 实例属性
  y: number = 0             // 带默认值
  readonly id: string        // 只读
  private secret = '🔒'      // 仅类内可见
  protected tag = 'p'        // 类及子类可见
  static origin = new Point(0, 0)   // 静态成员属于类本身

  constructor(x: number, private label: string) {  // 参数属性：自动成为成员
    this.x = x
    this.id = Math.random().toString(36)
  }

  move(dx: number): void { this.x += dx }
}

const p = new Point(1, 'a')
// p.secret          // ❌ private，外部不可访问

// 作为类型使用：声称"某个值是 Point 的实例"
let q: Point = new Point(2, 'b')
```

**继承与抽象**

```ts
abstract class Shape {
  abstract area(): number          // 抽象方法，子类必须实现
  describe(): string { return `area=${this.area()}` }
}

class Circle extends Shape {
  constructor(private r: number) { super() }
  area() { return Math.PI * this.r ** 2 }
}
```

**实现接口**

```ts
interface Named { name: string }
class Pet implements Named { name = 'cat' }
```

---

## 二、常见场景与注意事项

- 需要**封装状态 + 行为**、需要 `new`、需要继承体系时使用。
- 只描述数据形状、无行为时，优先用 [[interface]]（更轻、更贴近"数据结构"）。

> [!tip] `class` 名既是值又是类型
> ```ts
> const C = Point            // ✅ 作为值
> let p: Point               // ✅ 作为类型
> ```
> 而 `interface` 只存在于类型世界，不能 `new`。

> [!warning] 结构类型下的"私有字段"很关键
> TS 是结构类型，但**带 `private`/`protected` 成员的类**只有在"同源"时才算兼容——不同类即便形状一样也不互相赋值。想要"名义类型"效果，`private` 是个技巧。

> [!note] 修饰符在编译后会消失吗？
> `private`/`protected` 是**编译期**限制，产物里仍是普通属性（JS 的 `#private` 才是运行时真私有）。类型信息在编译时被擦除，见 [[解析产物说明]]。

> [!tip] 参数属性 `constructor(private x: T)`
> 一行同时完成"声明成员 + 赋值"，是 TS 特有语法（`useDefineForClassFields` 等配置下行为略有差异）。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `class` 实例 → 其 `interface` | ✅ 只要形状满足 |
| `class` → `unknown` / `any` | ✅ |
| `class` 与 `interface` | 类可 `implements`；interface 不能 `new` |
| 子类 → 父类 | ✅（子类实例是父类的子类型） |
| 父类 → 子类 | ❌ 需断言或收窄 |
| 与 `enum` | 无直接赋值关系；枚举见 [[enum]] |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 对象类型（Object） |
| 关键字 | `class` / `extends` / `implements` |
| 双重身份 | 值（可 `new`）＋ 类型（描述实例） |
| 成员可见性 | `public` / `protected` / `private` / `#真私有` |
| 静态成员 | `static`，属于类本身而非实例 |
| 抽象类 | `abstract`，不可实例化，强制子类实现 |
| 编译后 | 修饰符仅编译期生效，类型被擦除 |

---

## 相关笔记

- [[interface]] —— 只描述形状、不能 `new` 的"轻量契约"
- [[enum]] —— 类中常配合使用的具名常量
- [[array]] —— 数组也是对象类型
- [[解析产物说明]] —— 类编译成 JS 后长什么样
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Classes / Abstract Classes / Parameter Properties
