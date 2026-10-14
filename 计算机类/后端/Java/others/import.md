# 概念

==`import` 是用来「引入别的包里的类」的语句==，写在 `package` 之后、类定义之前。

它的作用是：==告诉编译器，我要用的某个类（或某个静态成员）在哪个包里==，这样在代码里就能用**简单的类名**，而不用每次都写一长串**全限定名**。

```java
package com.example.demo;   // 1. 声明自己所在的包

import java.util.ArrayList; // 2. 引入别人包里的类

public class Demo {
    public static void main(String[] args) {
        ArrayList<String> list = new ArrayList<>(); // 直接用简单类名
    }
}
```

如果**不写** `import`，就只能写全限定名：

```java
java.util.ArrayList<String> list = new java.util.ArrayList<>();
```

> 结论：`import` 不改变程序功能，==只是让代码更短、更好读==。

---

# 为什么需要 import —— 先理解「包」~~~~

Java 的类是按**包（package）**分目录存放的，包名本质上就是「类的身份证前缀」。

```java
java.util.ArrayList   // java.util 是包名，ArrayList 是类名
```

全限定名 = `包名 + 类名`。JVM 靠它唯一定位一个类。

但是每次写 `java.util.ArrayList` 太啰嗦，于是有了 `import`：==把「包名」提前登记好，后面只写「类名」==。

---

# 三种写法

## 1. 单类型导入（最常用）

一次只引入**一个**类。

```java
import java.util.ArrayList;
import java.util.HashMap;
```

## 2. 按需导入 / 通配符导入

用 `*` 引入==一个包下所有类==。

```java
import java.util.*;   // 引入 java.util 包下所有类
```

> ⚠️ 注意：`*` 只是「按需引入」，==并不是把整个包加载进内存==，编译时只引入**实际用到的那几个类**，对性能没有影响。它只是让代码可读性变差一点（看不出具体用了谁），大项目里一般更推荐写法 1。

## 3. 静态导入（`import static`）

普通 `import` 引入的是**类**；`import static` 引入的是==类里的静态成员（静态方法 / 静态常量）==，引入后可以直接写方法名，不用加类名。

```java
import static java.lang.Math.PI;
import static java.lang.Math.max;

public class Demo {
    public static void main(String[] args) {
        System.out.println(PI);        // 不用写 Math.PI
        System.out.println(max(3, 5)); // 不用写 Math.max
    }
}
```

也可以整体引入：

```java
import static java.lang.Math.*;  // 引入 Math 里所有静态成员
```

> ⚠️ 静态导入容易让代码「看不出这个方法是谁的」，==一般只在测试代码（如 `Assertions`）或常量极多时才用==，日常业务代码慎用。

---

# 什么时候可以不写 import

| 情况 | 是否需要 import | 说明 |
|------|----------------|------|
| 使用 `java.lang` 包下的类 | ❌ 不需要 | ==`java.lang` 是自动导入的==，如 `String`、`System`、`Math`、`Integer` |
| 同一个包下的类 | ❌ 不需要 | 同包直接写类名 |
| 跨包使用其他类 | ✅ 需要 | 否则只能写全限定名 |
| 使用 `import static` 的静态成员 | ✅ 需要 | 想省掉类名就得静态导入 |

```java
public class Demo {
    public static void main(String[] args) {
        String s = "hello";        // java.lang，不用 import
        System.out.println(s);     // java.lang，不用 import
        System.out.println(Math.PI); // java.lang，不用 import
    }
}
```

---

# 同名类冲突

如果两个包里都有同名类，==两个都 import 会直接编译报错==：

```java
import java.util.Date;
import java.sql.Date;   // ❌ 错误：Date 已经导入过（冲突）
```

解决办法：==只 import 一个，另一个用全限定名==。

```java
import java.util.Date;

public class Demo {
    public static void main(String[] args) {
        Date d1 = new Date();                   // 用的是 java.util.Date
        java.sql.Date d2 = new java.sql.Date(0); // 用全限定名区分
    }
}
```

> 或者只写 `import java.util.*;`，再对冲突的那个用全限定名，也能绕开。

---

# 语法位置与顺序

`import` 必须写在**所有类定义之前**，且==在 `package` 语句之后==。

```java
package com.example;      // ① 包声明（只能有一条，且必须在最前面）

import java.util.List;    // ② import（可以有多条）
import java.util.Map;

public class Demo {       // ③ 类定义
    // ...
}
```

> 一个 `.java` 文件里==最多只能有一条 `package` 语句==，但 `import` 可以有很多条。

---

# 常见误区

1. **`import` 不是「包含代码」**
   Java 的 `import` 和 C/C++ 的 `#include` 完全不同。`#include` 是把文件内容**复制粘贴**进来；`import` ==只是一个「名字的别名登记」，不加载任何代码==，真正的类加载发生在运行时。

2. **`import java.util.*;` 不会拖慢程序**
   见上文「按需导入」，编译期只挑用到的类。

3. **`import` 不能引入「包里的子包」**
   `import java.util.*;` ==不会==引入 `java.util.concurrent` 下的类，子包必须单独导入。

4. **`import` 不影响访问权限**
   一个类即便 import 进来了，如果它是 `private` 或包级私有（默认），==该访问不到还是访问不到==。`import` 解决的是「叫什么名字」，权限修饰符解决的是「能不能用」。

---

# 小结

| 写法 | 作用 | 示例 |
|------|------|------|
| `import 包名.类名;` | 引入一个类 | `import java.util.List;` |
| `import 包名.*;` | 引入一个包下所有类 | `import java.util.*;` |
| `import static 包名.类名.成员;` | 引入静态成员 | `import static java.lang.Math.PI;` |
| 不写 | `java.lang` 与同包类 | `String`、`System` |
| 全限定名 | 不 import 时直接写全路径 | `java.util.ArrayList` |

> **一句话记忆**：
> ==`import` 就是「先报个到，后面就能叫小名」——报的是包名，省的是类名。==
