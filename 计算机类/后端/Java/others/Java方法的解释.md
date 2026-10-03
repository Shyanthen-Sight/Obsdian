# 问题1：如果我要在 main 函数中引用方法，该怎么做

## 前提：先搞懂 main 方法是 static 的

```java
public static void main(String[] args) {
    // ...
}
```

`static` 表示==**这个方法属于类，而不是属于某个对象**==。它在 `new` 出任何对象之前就已经存在、就能被调用。

这一个特性决定了 main 里的调用规则：

- main 里**可以**直接调用**静态方法**（同类中）
- main 里**不能**直接调用**实例方法**，必须先 `new` 一个对象出来

---

## 方式一：调用静态方法

### 1. 同类中调用 —— 直接写方法名

```java
public class Demo {

    // 静态方法
    public static int add(int a, int b) {
        return a + b;
    }

    public static void main(String[] args) {
        int result = add(3, 5);   // ✅ 同类中直接调用，不用加类名
        System.out.println(result); // 8
    }
}
```

### 2. 跨类调用 —— 类名.方法名()

前提：
1. 被调用==的方法必须是 **`static`静态方法==**
2. 方法的**访问修饰符允许访问**（==一般写`public`，外部类才能访问；如果是 private，别的类不能调用==）
3. ==两个类在**同一个包下**==；
4. 如果不在同一个包，==需要 import 导入类==

```java
public class MathUtil {
    public static int add(int a, int b) {
        return a + b;
    }
}
```

```java
public class Demo {
    public static void main(String[] args) {
        int result = MathUtil.add(3, 5);  // ✅ 类名.方法名()
        System.out.println(result);       // 8
    }
}
```

> **要点**：静态方法不需要 `new` 对象，直接用 **类名** 点出来就行。
> 常见的 `Math.abs()`、`Arrays.sort()`、`Integer.parseInt()` 都是这个用法。

---

## 方式二：调用【实例方法】（方法没有 static）

==实例方法属于**对象**，所以必须先有对象，才能调用。==

### 1. 同类中调用 —— 先 new 本类对象

```java
public class Demo {

    // 实例方法（没有 static）
    public int multiply(int a, int b) {
        return a * b;
    }

    public static void main(String[] args) {
        Demo demo = new Demo();          // 先创建对象
        int result = demo.multiply(3, 5); // ✅ 用对象名调用
        System.out.println(result);       // 15
    }
}
```

### 2. 跨类调用 —— new 目标类的对象

```java
public class Calculator {
    public int multiply(int a, int b) {   // 实例方法
        return a * b;
    }
}
```

```java
public class Demo {
    public static void main(String[] args) {
        Calculator calculator = new Calculator();
        int result = calculator.multiply(3, 5);  // ✅ 对象名.方法名()
        System.out.println(result);              // 15
    }
}
```

### 3. 为什么不能直接调用？—— 最常见的报错

如果在 main 里直接写 `multiply(3, 5)`，编译器会报：

```
Non-static method multiply(int,int) cannot be referenced from a static context
（非静态方法 multiply 不能在静态上下文中引用）
```

原因：==**实例方法依赖对象里的数据（成员变量），而 main 执行时对象还不存在**==。
编译器不知道该给哪个对象用这个方法，所以直接拒绝编译。

> **记忆口诀**：
> **==静态方法看类，实例方法看对象。**==
> 调用前先问自己一句：这个方法属于「类」还是「对象」？

---

## 方式三：跨文件调用

Java 里一个文件（`.java`）通常对应一个类。跨文件调用本质上就是**跨类调用**，但还多了「包（package）」这一层，所以有三个前提条件：

| 条件                    | 说明                           |
| --------------------- | ---------------------------- |
| ==类必须是 `public`==     | 否则别的包/文件访问不到                 |
| 方法必须是 `public`（或至少可见） | 权限修饰符决定能不能被外部调用              |
| 包的处理                  | 同包不用 `import`；不同包必须 `import` |

### 场景：两个文件在同一个包下（最简单）

目录结构：

```
src/
  └── com/example/
        ├── MathUtil.java
        └── Demo.java
```

**MathUtil.java**

```java
package com.example;      // 声明自己所在的包

public class MathUtil {
    public static int add(int a, int b) {   // 静态方法
        return a + b;
    }

    public int multiply(int a, int b) {     // 实例方法
        return a * b;
    }
}
```

**Demo.java**

```java
package com.example;      // 同一个包

public class Demo {
    public static void main(String[] args) {
        // 静态方法：类名.方法名()
        System.out.println(MathUtil.add(3, 5));          // 8

        // 实例方法：先 new，再调用
        MathUtil util = new MathUtil();
        System.out.println(util.multiply(3, 5));         // 15
    }
}
```

> 同一个包下，**不用写 `import`**，直接用类名即可。

### 场景：两个文件在不同包下

目录结构：

```
src/
  ├── com/example/utils/
  │     └── MathUtil.java
  └── com/example/demo/
        └── Demo.java
```

**MathUtil.java**

```java
package com.example.utils;

public class MathUtil {
    public static int add(int a, int b) {
        return a + b;
    }
}
```

**Demo.java**

```java
package com.example.demo;

import com.example.utils.MathUtil;   // ⚠️ 跨包必须 import

public class Demo {
    public static void main(String[] args) {
        System.out.println(MathUtil.add(3, 5));  // 8
    }
}
```

也可以不 import，直接写**全限定名**：

```java
com.example.utils.MathUtil.add(3, 5);
```

> 这种方式一般只在「两个同名类冲突」时用，平时还是 import 更清爽。



---

## 三种方式对比

| 方式 | 调用写法 | 需要 new 吗 | 需要 import 吗 |
|------|----------|-------------|----------------|
| 同类静态方法 | `方法名()` | 不需要 | 不需要 |
| 跨类静态方法 | `类名.方法名()` | 不需要 | 不同包时需要 |
| 同类实例方法 | `new 本类().方法名()` | 需要 | 不需要 |
| 跨类实例方法 | `new 目标类().方法名()` | 需要 | 不同包时需要 |

---


