---
tags:
  - Java
  - 关键字
---

# final 关键字

> **一句话**：`final` = 最终的、不可改变的 —— 修饰**变量** → 变成常量、修饰**方法** → 不能被子类重写、修饰**类** → 不能被继承。三种位置用法不同，本质都是 ==“锁死，不许再改”==。

## 一、概念

**定义**：Java 中，final 表示最终，也可以称为==完结器==，表示==对象是最终形态==的，==不可改变==的意思。

**用途**：final 应用于类、方法和变量时意义是不同的，但本质是一样的，==都表示不可改变==。

**使用注意事项：**

1）final 修饰变量，表示变量的值不可改变，此==时该变量可被称为常量==。

2）final 修饰方法，==表示方法不能被子类重写==；

3）final 用在类的前面表示该类不能有子类，即该类不可以被继承。

### 三种用法对照表

| 修饰对象 | 写法               | 含义                     | 通俗理解        |
| ---- | ---------------- | ---------------------- | ----------- |
| 变量   | `final int A;`   | 值不可改变，成为**常量**         | 贴了封条，只能读不能写 |
| 方法   | `final void f()` | **不能被子类重写**，但可以继承、可以调用 | 祖传手艺，后人只能照做 |
| 类    | `final class C`  | **不能有子类**（不可被继承）       | 到此为止，不会再有后代 |

## 二、final 修饰变量（常量）

### 1. 三条铁律

- **只能赋值一次**：赋值之后再赋值，直接编译报错
- **必须初始化**：要么声明时赋值，要么在构造方法（静态变量则是静态代码块）中赋值
- **修饰引用类型 ≠ 对象不可变**：锁住的是“引用”，不是“对象里的内容”

### 2. 基本类型 vs 引用类型（重点）

```java
public class FinalDemo {
    // ① 基本类型：值被锁死
    final int AGE = 18;
    // AGE = 20;                  // ❌ 编译错误：无法为 final 变量 'AGE' 赋值

    // ② 引用类型：地址被锁死，但对象内容可以改
    final int[] ARR = {1, 2, 3};
    // ARR = new int[]{4, 5, 6};  // ❌ 编译错误：不能再指向新数组
    ARR[0] = 100;                  // ✅ 合法：数组里的元素可以修改

    final StringBuilder SB = new StringBuilder("Hello");
    SB.append(" World");           // ✅ 合法：对象内容可变
    // SB = new StringBuilder();   // ❌ 编译错误：引用不可变
}
```

> **结论**：`final` 修饰引用类型时，只保证“这个变量永远指向同一个对象”，不保证“这个对象不会被修改”。想要真正的不可变对象，还要靠 `private final` 字段 + 不提供 setter 的设计（`String` 就是这么做的）。

### 3. 变量位置不同，初始化方式不同

| 变量类型      | 位置        | 初始化要求          | 初始化时机                     |
| --------- | --------- | -------------- | ------------------------- |
| 局部变量      | 方法内部      | 使用前必须赋值        | 声明时，或使用前任意时刻（只能赋一次）       |
| 成员变量（实例）  | 类中、方法外    | 必须显式初始化，不能靠默认值 | 声明时 / 构造代码块 / 构造方法        |
| 静态变量 + static | 类中 + `static` | 必须显式初始化        | 声明时 / 静态代码块               |

**① 成员变量的三种初始化方式**

```java
// 方式一：声明时直接赋值（最常用）
class Person {
    final String name = "张三";
}

// 方式二：构造方法中赋值（值由外部传入时）
class Person {
    final String name;

    Person(String name) {
        this.name = name;      // ✅ 空白 final 字段在构造方法中赋值
    }
}

// 方式三：构造代码块中赋值
class Person {
    final String name;

    {
        name = "默认名";        // ✅ 实例初始化块
    }
}
```

**② 静态变量的初始化**

```java
class Config {
    static final int MAX_SIZE = 100;   // 声明时赋值
    static final String VERSION;       // 声明时不赋值（空白 final 静态字段）

    static {
        VERSION = "v1.0";              // ✅ 静态代码块中赋值
    }
}
```

> ⚠️ **易错点**：普通成员变量即使不赋值也有默认值（`null` / `0`），但一旦加上 `final`，就**必须手动初始化**，否则编译报错：`变量 name 可能尚未初始化`。

**③ 每个构造方法都要保证赋值**

```java
class Person {
    final String name;

    Person() {
        this.name = "无名";       // ✅ 必须赋
    }

    Person(String name) {
        this.name = name;         // ✅ 必须赋
    }
    // 若有任何一个构造方法漏了赋值 → ❌ 编译错误：变量 name 可能尚未初始化
}
```

### 4. final 修饰参数与局部变量

```java
public void test(final int num) {
    // num = 10;      // ❌ 编译错误：final 形参在方法内不能重新赋值
    System.out.println(num);
}

public void method() {
    final int a;
    a = 1;            // ✅ 第一次赋值（延迟初始化）
    // a = 2;         // ❌ 第二次赋值，编译错误
}
```

> **延伸**：Java 8 之前，匿名内部类访问的局部变量**必须**显式写 `final`；Java 8 起，只要该变量“事实上没被改过”（effectively final）就可以省略。Lambda 表达式捕获的变量同理。

### 5. 命名规范

- 普通 `final` 变量：小驼峰，如 `final int maxAge`
- `static final` 常量：**全大写 + 下划线分隔**，如 `static final int MAX_VALUE = 100;`
- 修饰符推荐顺序：`public static final`（static 在前，final 在后）

## 三、final 修饰方法

### 1. 规则

- 被 `final` 修饰的方法**不能被子类重写（override）**
- 但**可以被子类继承并调用**（只是不能改）
- 也**可以被重载（overload）**——final 只挡重写，不挡重载
- `private` 方法本身就是“隐式 final”（子类根本继承不到，谈不上重写）

### 2. 示例

```java
class Father {
    public final void show() {
        System.out.println("Father.show() —— 谁也不能改我");
    }

    // 重载：同一个类中方法名相同、参数不同，合法
    public final void show(int n) {
        System.out.println("重载版本：" + n);
    }
}

class Son extends Father {
    // ❌ 编译错误：show() 在 Father 中已被声明为 final，无法重写
    // @Override
    // public void show() { }

    public void call() {
        show();       // ✅ 合法：继承过来直接调用
        show(10);     // ✅ 合法：重载版本同样可继承
    }
}
```

> **易混**：final 只禁止**重写**（子类改掉父类已有的行为），不禁止**重载**（同名但参数不同的新方法）。

## 四、final 修饰类

### 1. 规则

- 被 `final` 修饰的类**不能有子类**（不能被继承）
- 该类的**成员方法都隐式是 final**（已经没有子类，自然谈不上重写）
- 但类的**成员变量不会自动变成 final**（这是常被搞混的一点）
- `final` 与 `abstract` **不能同时修饰**一个类（abstract 必须被继承才有意义，自相矛盾 → 编译错误）

### 2. 示例

```java
final class Animal {
    public void eat() {
        System.out.println("吃东西");
    }
}

// ❌ 编译错误：无法从最终类 Animal 进行继承
// class Dog extends Animal { }
```

### 3. JDK 中常见的 final 类

| 类                        | 说明                    |
| ------------------------ | --------------------- |
| `String`                 | 字符串不可变，保证安全与线程安全      |
| `Integer` / `Double` 等包装类 | 包装类全部是 final          |
| `Math` / `System`        | 工具类，只提供静态方法           |
| `StringBuilder` / `StringBuffer` | 类本身仍不允许被继承            |

## 五、易混点 / 面试陷阱

### 1. final、finally、finalize（长得像，其实毫无关系）

| 关键字          | 出处               | 作用                                        |
| ------------ | ---------------- | ----------------------------------------- |
| `final`      | 修饰符              | 最终的、不可改变的（变量 / 方法 / 类）                     |
| `finally`    | 异常处理             | `try-catch-finally` 中无论是否发生异常都会执行的代码块     |
| `finalize()` | `Object` 类的方法     | 对象被 GC 回收前调用的“遗言”方法（JDK 9 起已废弃，不推荐使用）      |

```java
try {
    int x = 1 / 0;                            // 抛异常
} catch (ArithmeticException e) {
    System.out.println("捕获到异常");
} finally {
    System.out.println("finally 一定执行");     // ← 是 finally，不是 final
}
```

### 2. ==`final` ,`static final`,`public static final`
==


### 3. 其他常见坑

1. **final 变量未初始化** → 编译错误，必须赋初值
2. **某个构造方法漏给 final 成员赋值** → 编译错误
3. **`final` 修饰引用 = 引用不可变，内容可变**，不等于“对象不可变”
4. **final 类的成员变量不自动 final**
5. **private 方法 = 隐式 final**，再写 `final` 是多余的
6. **`abstract` 与 `final` 不能同时修饰**同一个类或方法

## 六、为什么用 final（使用场景）

1. **定义常量**：`public static final double PI = 3.14159;`
2. **保护关键方法不被子类篡改**：模板方法模式中固定算法骨架
3. **设计不可变类**：`final class` + `private final` 字段 + 无 setter（`String` 就是范例）
4. **防止继承带来的安全隐患**：不希望别人扩展你的实现
5. **参数 / 局部变量加 final**：防止手滑重新赋值，让代码意图更明确
6. **（历史）性能优化**：早期 JVM 依赖 final 做内联优化，现代 JIT 已能自动判断，这条意义已不大

## 七、速查总结

| 用法             | 效果               | 常见错误           |
| -------------- | ---------------- | -------------- |
| `final 变量`     | 只能赋值一次，成为常量      | 未初始化 / 二次赋值    |
| `final 引用类型`   | 引用不可变，内容可改       | 误以为整个对象都不可变    |
| `final 方法`     | 不能重写，但可继承、可重载    | 和“重载”混淆        |
| `final 类`      | 不能被继承            | 与 `abstract` 同用 |
| `final 参数`     | 方法内不能重新赋值        | ——             |

**一句话记忆**：`final` 就是一把锁——锁变量（值不变）、锁方法（不被重写）、锁类（不被继承）。
