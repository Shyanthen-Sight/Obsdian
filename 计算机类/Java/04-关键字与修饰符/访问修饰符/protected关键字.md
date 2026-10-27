# protected 关键字

`protected` 是 Java 的访问修饰符之一，用于控制类、方法、构造器和成员变量的可见性。

## 访问范围

| 位置 | 是否可访问 |
|------|-----------|
| 同一个类中 | ✅ |
| 同一个包中 | ✅ |
| 不同包的子类 | ✅ |
| 不同包的非子类 | ❌ |

> **一句话记忆**：`protected` = 同包可见 + 跨包子类可见。

## 使用场景

- 希望成员能被**子类继承和重写**，但不想完全暴露给外部。
- 设计可扩展的类库，允许子类访问内部实现细节。
- 比 `private` 更开放，比 `public` 更安全。

## 代码示例

### 父类（包 `com.example.base`）

```java
package com.example.base;

public class Animal {
    protected String name;

    protected void sayHello() {
        System.out.println("Hello, I'm " + name);
    }
}
```

### 子类（不同包）

```java
package com.example.child;

import com.example.base.Animal;

public class Dog extends Animal {
    public void bark() {
        name = "Buddy";        // ✅ 可以访问 protected 成员
        sayHello();            // ✅ 可以调用 protected 方法
    }
}
```

### 不同包的非子类

```java
package com.example.other;

import com.example.base.Animal;

public class Test {
    public void demo() {
        Animal animal = new Animal();
        // animal.name = "Tom";      // ❌ 编译错误
        // animal.sayHello();        // ❌ 编译错误
    }
}
```

## 注意事项

1. **构造器也可以是 `protected`**：这样只有同包类或子类能创建实例，常用于限制外部直接 `new`。
2. **与继承相关**：`protected` 成员的访问权限依赖于继承关系，而不仅仅是引用类型。
3. **不要滥用**：过度使用会破坏封装，让子类过度依赖父类实现细节。

## 与其他修饰符对比

| 修饰符 | 同类 | 同包 | 子类 | 全局 |
|--------|------|------|------|------|
| `private` | ✅ | ❌ | ❌ | ❌ |
| 默认（无修饰符） | ✅ | ✅ | ❌ | ❌ |
| `protected` | ✅ | ✅ | ✅ | ❌ |
| `public` | ✅ | ✅ | ✅ | ✅ |

## 总结

`protected` 是面向对象设计中**封装与继承的折中方案**，适合需要让子类访问、但不想完全公开的场景。理解它的访问边界，有助于写出更合理的类层次结构。
