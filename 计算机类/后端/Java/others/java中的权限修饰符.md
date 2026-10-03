# Java 中的权限修饰符

## 一、四种访问权限一览

| 修饰符         | 同类  | 同包  | 子类  | 任意类 |
| ----------- | --- | --- | --- | --- |
| `private`   | ✅   | ❌   | ❌   | ❌   |
| 默认（缺省/包权限）  | ✅   | ✅   | ❌   | ❌   |
| `protected` | ✅   | ✅   | ✅   | ❌   |
| `public`    | ✅   | ✅   | ✅   | ✅   |

> **记忆口诀**：`private` 最严，`public` 最宽；`protected` 比默认多了一个“跨包子类可见”。

---

## 二、各自含义

### 1. `private` —— 私有
- 只能在本类内部访问。
- 常用于封装字段，配合 `getter` / `setter` 使用。

### 2. 默认（不写修饰符）—— 包权限
- 同一个包内的类可以访问。
- 不同包，即使是子类，也不能访问。

### 3. `protected` —— 受保护
- 同一个包内可访问。
- 不同包的子类中也可以访问（通常通过继承）。

### 4. `public` —— 公共
- 任何类、任何包都能访问。
- 用于对外暴露的接口或 API。

---

## 三、举例分析

### 示例 1：`private` 的封装作用

```java
public class Person {
    private String name;   // 私有字段，外部不能直接修改
    private int age;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        if (age >= 0) {
            this.age = age;
        } else {
            System.out.println("年龄不能为负数");
        }
    }
}
```

**分析**：
- `name` 和 `age` 是 `private`，外部无法直接 `person.age = -10`。
- 通过 `setAge` 可以在赋值时做校验，保证数据合法性。
- 这就是 **封装** 的核心：隐藏实现细节，提供受控访问。

---

### 示例 2：默认权限与 `protected` 的区别

包结构：

```
com.example.base/
    └── Animal.java
com.example.test/
    └── Dog.java（继承 Animal）
```

**Animal.java**（在 `com.example.base` 包中）：

```java
package com.example.base;

public class Animal {
    String name;           // 默认权限
    protected int age;     // 受保护权限

    public void show() {
        System.out.println(name + " " + age);
    }
}
```

**Dog.java**（在 `com.example.test` 包中）：

```java
package com.example.test;

import com.example.base.Animal;

public class Dog extends Animal {
    public void printInfo() {
        // System.out.println(name);  // ❌ 编译错误！默认权限在不同包子类中不可见
        System.out.println(age);      // ✅ protected 在不同包子类中可见
    }
}
```

**分析**：
- `name` 是默认权限，`Dog` 虽然在子类中，但跨越了包，所以无法访问。
- `age` 是 `protected`，允许跨包子类访问。
- 这说明：`protected > 默认权限`，区别就在于**不同包的子类**。

---

### 示例 3：`public` 的开放访问

```java
package com.example.utils;

public class MathUtil {
    public static int add(int a, int b) {
        return a + b;
    }
}
```

任意其他类：

```java
import com.example.utils.MathUtil;

public class Demo {
    public static void main(String[] args) {
        int result = MathUtil.add(3, 5);  // ✅ 任意位置可访问
        System.out.println(result);
    }
}
```

**分析**：
- `public` 方法作为工具类 API，供所有类调用。
- 工具类的方法通常声明为 `public static`，方便直接使用。

---

## 四、使用建议

1.  **字段优先 `private`**：保护数据，避免外部随意修改。
2. **方法按需开放**：
   - 只在类内部使用 → `private`
   - 同包协作使用 → 默认
   - 需要被继承但不想完全公开 → `protected`
   - 对外 API → `public`
3. **不要滥用 `public`**：过度暴露会增加耦合，破坏封装。
4. **构造方法也可以私有**：例如单例模式中，`private` 构造方法防止外部 `new`。

---

## 五、一句话总结

> ==**`private` 藏自己，默认藏外包，`protected` 给继承，`public` 全开放==。**
