# static 关键字

## 1. 什么是 static

`static` 是 Java 中的**修饰符关键字**，表示"**静态的**"。它的核心含义是：被修饰的成员**属于类本身**，而不是属于类的某个实例对象。

### 1.1 核心特征

- ==**类级别成员**==：被 `static` 修饰的变量、方法、代码块等，都随类的加载而创建==，与具体对象无关。
- **无需创建对象**：==可以直接通过**类名**访问==，不依赖 `new` 出来的实例。
- ==**全局共享**==：所有实例共享同一份 `static` 成员，一处修改，全局可见。
- **生命周期长**：从类加载开始，到程序结束或类卸载才销毁。

### 1.2 语法形式

```java
public class Demo {
    static int count;           // 静态变量
    static void show() {}       // 静态方法
    static {}                   // 静态代码块
    static class Inner {}       // 静态内部类
}
```

### 1.3 为什么需要 static

| 场景   | 原因                             |
| ---- | ------------------------------ |
| 工具类  | 如 `Math`、`Collections`，不需要创建对象 |
| 共享数据 | 如计数器、全局配置                      |
| 常量定义 | 如 `Math.PI`                    |
| 类初始化 | 如加载驱动、读取静态配置                   |


---

## 2. static 可修饰的内容

### 2.1 静态变量（类变量 / Class Variable）

#### 2.1.1 基本定义

```java
public class Student {
    // 静态变量：所有 Student 对象共享
    static String school = "清华大学";
    
    // 实例变量：每个对象独立拥有
    String name;
    int age;
}
```

#### 2.1.2 访问方式

```java
Student s1 = new Student();
Student s2 = new Student();

// 推荐：通过类名访问
Student.school = "北京大学";

// 语法允许，但不推荐：通过对象访问
s1.school = "复旦大学";

// s2 看到的 school 也会改变
System.out.println(s2.school);  // 复旦大学
```

#### 2.1.3 与实例变量的对比

| 特性     | 静态变量     | 实例变量     |
| ------ | -------- | -------- |
| 所属     | 类        | 对象       |
| 访问方式   | `类名.变量名` | `对象.变量名` |
| 内存分配时机 | 类加载时     | 对象创建时    |
| 内存份数   | 只有一份     | 每个对象一份   |
| 存储区域   | 方法区/元空间  | 堆内存      |
| 生命周期   | 与类相同     | 与对象相同    |

#### 2.1.4 使用场景

- **计数器**：统计创建了多少个对象。
- **全局配置**：如数据库连接池大小、应用名称。
- **共享状态**：如缓存、会话上下文（需谨慎）。

```java
public class User {
    static int userCount = 0;  // 计数器
    
    public User() {
        userCount++;
    }
}
```

#### 2.1.5 注意事项

- 静态变量在内存中只有一份，**多线程环境下要考虑线程安全问题**。
- ==不建议用对象引用访问静态变量==，会降低代码可读性。
- ==静态变量生命周期长，过度使用容易造成**内存泄漏**==。

---

### 2.2 静态方法（类方法 / Class Method）

#### 2.2.1 基本定义

```java
public class MathUtil {
    public static int add(int a, int b) {
        return a + b;
    }
    
    public static double circleArea(double r) {
        return Math.PI * r * r;
    }
}
```

#### 2.2.2 调用方式

```java
// 推荐
int sum = MathUtil.add(3, 5);

// 语法允许，但不推荐
MathUtil util = new MathUtil();
int sum2 = util.add(3, 5);
```

#### 2.2.3 静态方法的限制

```java
public class Example {
    int instanceVar = 10;        // 实例变量
    static int staticVar = 20;   // 静态变量
    
    void instanceMethod() {}     // 实例方法
    static void staticMethod() { // 静态方法
        // ❌ 编译错误：无法访问实例变量
        // System.out.println(instanceVar);
        
        // ❌ 编译错误：无法调用实例方法
        // instanceMethod();
        
        // ✅ 可以访问静态变量
        System.out.println(staticVar);
        
        // ❌ 编译错误：不能使用 this
        // System.out.println(this);
        
        // ❌ 编译错误：不能使用 super
        // System.out.println(super);
    }
}
```

#### 2.2.4 为什么静态方法不能访问非静态成员？

静态方法在类加载后就存在了，此时可能还没有创建任何对象。而非静态成员必须依赖具体的对象实例（需要 `this` 指向）。JVM 在调用静态方法时，不会隐式传入 `this` 引用，因此无法确定要访问哪个对象的成员。

#### 2.2.5 常见 JDK 中的静态方法

| 类 | 静态方法 |
|----|---------|
| `Math` | `Math.max()`, `Math.min()`, `Math.sqrt()` |
| `Arrays` | `Arrays.sort()`, `Arrays.toString()`, `Arrays.copyOf()` |
| `Collections` | `Collections.sort()`, `Collections.emptyList()` |
| `Integer` | `Integer.parseInt()`, `Integer.valueOf()` |
| `System` | `System.currentTimeMillis()`, `System.exit()` |

#### 2.2.6 使用场景

- **工具类方法**：如字符串处理、数学计算。
- **工厂方法**：如 `Integer.valueOf()`。
- **入口方法**：`public static void main(String[] args)`。

---

### 2.3 静态代码块（Static Block）

#### 2.3.1 基本定义

```java
public class Demo {
    static {
        System.out.println("静态代码块执行");
    }
    
    public Demo() {
        System.out.println("构造方法执行");
    }
}
```

#### 2.3.2 执行时机

```java
public class Test {
    public static void main(String[] args) {
        new Demo();  // 先输出"静态代码块执行"，再输出"构造方法执行"
        new Demo();  // 只输出"构造方法执行"，静态代码块不再执行
    }
}
```

#### 2.3.3 多个静态代码块

```java
public class Demo {
    static {
        System.out.println("静态代码块 1");
    }
    
    static {
        System.out.println("静态代码块 2");
    }
}
// 输出：
// 静态代码块 1
// 静态代码块 2
```

#### 2.3.4 典型用途

- **初始化静态变量**：尤其是复杂初始化逻辑。
- **加载 JDBC 驱动**：`Class.forName("com.mysql.cj.jdbc.Driver")`。
- **读取配置文件**：如加载 `.properties` 文件。
- **注册 Native 方法**：JNI 开发中常见。

```java
public class DatabaseConfig {
    static String url;
    static String username;
    static String password;
    
    static {
        // 模拟读取配置
        url = "jdbc:mysql://localhost:3306/test";
        username = "root";
        password = "123456";
        System.out.println("数据库配置加载完成");
    }
}
```

---

### 2.4 静态内部类（Static Nested Class）

#### 2.4.1 基本定义

```java
public class Outer {
    private static int staticVar = 10;
    private int instanceVar = 20;
    
    // 静态内部类
    static class Inner {
        void show() {
            System.out.println(staticVar);      // ✅ 可以访问外部类静态成员
            // System.out.println(instanceVar); // ❌ 不能访问外部类非静态成员
        }
    }
}
```

#### 2.4.2 创建方式

```java
// 静态内部类不需要外部类实例
Outer.Inner inner = new Outer.Inner();
inner.show();
```

#### 2.4.3 与普通内部类的对比

| 特性 | 普通内部类 | 静态内部类 |
|------|-----------|-----------|
| 关键字 | 无 `static` | 有 `static` |
| 是否依赖外部类实例 | 是 | 否 |
| 创建方式 | `Outer.Inner inner = new Outer().new Inner()` | `Outer.Inner inner = new Outer.Inner()` |
| 能否访问外部类非静态成员 | 能 | 不能 |
| 能否访问外部类静态成员 | 能 | 能 |
| 是否持有外部类引用 | 是（可能导致内存泄漏） | 否 |

#### 2.4.4 经典应用

**Builder 模式**：

```java
public class Computer {
    private String cpu;
    private int ram;
    
    private Computer(Builder builder) {
        this.cpu = builder.cpu;
        this.ram = builder.ram;
    }
    
    public static class Builder {
        private String cpu;
        private int ram;
        
        public Builder cpu(String cpu) {
            this.cpu = cpu;
            return this;
        }
        
        public Builder ram(int ram) {
            this.ram = ram;
            return this;
        }
        
        public Computer build() {
            return new Computer(this);
        }
    }
}

// 使用
Computer computer = new Computer.Builder()
    .cpu("Intel i9")
    .ram(32)
    .build();
```

**枚举类中的静态内部类**：JDK 源码中常见。

---

### 2.5 静态导入（Static Import）

#### 2.5.1 基本用法

```java
import static java.lang.Math.*;

public class Test {
    public static void main(String[] args) {
        System.out.println(PI);        // 不需要 Math.PI
        System.out.println(max(3, 5)); // 不需要 Math.max
    }
}
```

#### 2.5.2 静态导入 vs 普通导入

| 类型 | 语法 | 作用 |
|------|------|------|
| 普通导入 | `import java.lang.Math` | 导入类 |
| 静态导入 | `import static java.lang.Math.PI` | 导入类的静态成员 |

#### 2.5.3 注意事项

- 静态导入可以导入单个静态成员，也可以导入全部：`import static java.lang.Math.*`。
- 过度使用会降低代码可读性，别人可能不知道 `max()` 来自哪里。
- 当多个类中有同名静态成员时，会产生命名冲突。

---

## 3. static 的内存机制

### 3.1 类加载过程

```
加载 → 验证 → 准备 → 解析 → 初始化
```

- **准备阶段**：为静态变量分配内存，并设置默认初始值。
- **初始化阶段**：执行静态变量赋值和静态代码块。

### 3.2 内存分布

```
┌─────────────────────────────────────────────────────────────┐
│                         方法区 / 元空间                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  类信息、常量池、静态变量、静态方法、即时编译器编译后的代码  │  │
│  │                                                       │  │
│  │   static int count = 0;                               │  │
│  │   static void show() {}                               │  │
│  │                                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │ 所有对象共享
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
   ┌─────────┐           ┌─────────┐           ┌─────────┐
   │ 对象 s1  │           │ 对象 s2  │           │ 对象 s3  │
   │ name    │           │ name    │           │ name    │
   │ age     │           │ age     │           │ age     │
   └─────────┘           └─────────┘           └─────────┘
        ▲                     ▲                     ▲
        └─────────────────────┴─────────────────────┘
                         堆内存
```

### 3.3 JDK 版本对 static 存储位置的影响

| JDK 版本 | 静态变量存储位置 |
|----------|----------------|
| JDK 7 及之前 | 永久代（PermGen） |
| JDK 8 及之后 | 元空间（MetaSpace），使用本地内存 |

### 3.4 静态变量的初始化时机

```java
public class Test {
    static int a = 10;           // 编译期可确定
    static int b = getValue();   // 运行时初始化
    
    static int getValue() {
        return 20;
    }
}
```

---

## 4. static 与继承

### 4.1 静态方法可以被继承，但不能被重写（Override）

```java
class Parent {
    public static void show() {
        System.out.println("Parent static show");
    }
}

class Child extends Parent {
    // 这是隐藏（hide），不是重写（override）
    public static void show() {
        System.out.println("Child static show");
    }
}

public class Test {
    public static void main(String[] args) {
        Parent.show();  // Parent static show
        Child.show();   // Child static show
        
        Parent p = new Child();
        p.show();       // Parent static show（编译时类型决定）
    }
}
```

### 4.2 静态方法隐藏（Hide） vs 实例方法重写（Override）

| 特性 | 静态方法隐藏 | 实例方法重写 |
|------|-------------|-------------|
| 关键字 | `static` | 无 |
| 多态性 | 不支持 | 支持 |
| 调用依据 | 编译时类型 | 运行时类型 |
| 注解 | 不能用 `@Override` | 可以用 `@Override` |

### 4.3 子类对父类静态成员的访问

```java
class Parent {
    static int count = 10;
}

class Child extends Parent {
    void print() {
        System.out.println(count);      // 可以访问父类静态变量
        System.out.println(Parent.count);
    }
}
```

---

## 5. static 的执行顺序

### 5.1 单个类的执行顺序

```java
public class Demo {
    static int a = 1;  // 1. 静态变量初始化
    
    static {           // 2. 静态代码块
        System.out.println("静态代码块");
    }
    
    {                 // 3. 构造代码块
        System.out.println("构造代码块");
    }
    
    public Demo() {    // 4. 构造方法
        System.out.println("构造方法");
    }
}
```

### 5.2 继承关系中的执行顺序

```java
class GrandParent {
    static { System.out.println("GrandParent 静态代码块"); }
    { System.out.println("GrandParent 构造代码块"); }
    GrandParent() { System.out.println("GrandParent 构造方法"); }
}

class Parent extends GrandParent {
    static { System.out.println("Parent 静态代码块"); }
    { System.out.println("Parent 构造代码块"); }
    Parent() { System.out.println("Parent 构造方法"); }
}

class Child extends Parent {
    static { System.out.println("Child 静态代码块"); }
    { System.out.println("Child 构造代码块"); }
    Child() { System.out.println("Child 构造方法"); }
}

// 执行 new Child() 输出：
// GrandParent 静态代码块
// Parent 静态代码块
// Child 静态代码块
// GrandParent 构造代码块
// GrandParent 构造方法
// Parent 构造代码块
// Parent 构造方法
// Child 构造代码块
// Child 构造方法
```

### 5.3 执行顺序总结

```
1. 父类静态代码块和静态变量初始化（按定义顺序）
2. 子类静态代码块和静态变量初始化（按定义顺序）
3. 父类构造代码块和构造方法
4. 子类构造代码块和构造方法
```

---

## 6. static vs final

### 6.1 单独使用

| 关键字 | 作用对象 | 含义 |
|--------|---------|------|
| `static` | 变量、方法、代码块、内部类 | 属于类，共享 |
| `final` | 变量、方法、类 | 不可变/不可重写/不可继承 |

### 6.2 组合使用：static final

```java
public class Constants {
    public static final double PI = 3.141592653589793;
    public static final int MAX_SIZE = 100;
    public static final String APP_NAME = "MyApplication";
}
```

### 6.3 static final 常量

- **编译期常量**：基本类型和 String，值在编译时确定，会被编译器优化（直接替换为常量值）。
- **运行时常量**：值在运行时确定，如通过方法返回值赋值。

```java
public class Test {
    // 编译期常量
    public static final int A = 10;
    
    // 运行时常量
    public static final int B = (int) (Math.random() * 100);
}
```

---

## 7. static 与线程安全

### 7.1 静态变量的线程安全问题

```java
public class Counter {
    private static int count = 0;
    
    public static void increment() {
        count++;  // 非原子操作，多线程下不安全
    }
}
```

### 7.2 解决方案

| 方案 | 代码示例 |
|------|---------|
| synchronized 方法 | `public static synchronized void increment()` |
| synchronized 代码块 | `synchronized(Counter.class) { count++; }` |
| 原子类 | `private static AtomicInteger count = new AtomicInteger(0)` |
| ThreadLocal | 为每个线程提供独立副本 |

### 7.3 静态 ThreadLocal

```java
public class UserContext {
    private static final ThreadLocal<String> currentUser = new ThreadLocal<>();
    
    public static void set(String user) {
        currentUser.set(user);
    }
    
    public static String get() {
        return currentUser.get();
    }
    
    public static void remove() {
        currentUser.remove();  // 防止内存泄漏
    }
}
```

---

## 8. static 与单例模式

### 8.1 饿汉式单例

```java
public class Singleton {
    private static final Singleton INSTANCE = new Singleton();
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        return INSTANCE;
    }
}
```

### 8.2 懒汉式单例（线程安全）

```java
public class Singleton {
    private static volatile Singleton instance;
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

### 8.3 静态内部类单例（推荐）

```java
public class Singleton {
    private Singleton() {}
    
    private static class Holder {
        private static final Singleton INSTANCE = new Singleton();
    }
    
    public static Singleton getInstance() {
        return Holder.INSTANCE;
    }
}
```

---

## 9. static 使用注意事项与最佳实践

### 9.1 注意事项

| 注意点 | 说明 |
|--------|------|
| 不要滥用 | 静态变量生命周期长，占用内存久 |
| 线程安全 | 多线程共享静态变量，需要同步 |
| 不能修饰局部变量 | 方法内的局部变量不能用 `static` |
| 不能修饰构造方法 | 构造方法用于创建对象，与 `static` 语义冲突 |
| 不能修饰顶层类 | 只有内部类可以被 `static` 修饰 |
| 避免在静态方法中使用 this/super | 编译会报错 |
| 注意内存泄漏 | 静态集合类持有大量对象引用时要小心 |

### 9.2 最佳实践

1. **工具类声明为 final 并私有化构造方法**

```java
public final class StringUtils {
    private StringUtils() {}  // 防止实例化
    
    public static boolean isEmpty(String str) {
        return str == null || str.isEmpty();
    }
}
```

2. **常量使用 static final**

```java
public final class Constants {
    public static final int MAX_RETRY = 3;
    public static final String DEFAULT_ENCODING = "UTF-8";
}
```

3. **避免使用可变成员变量作为 static**

```java
// 不推荐
public static List<String> cache = new ArrayList<>();

// 推荐
private static final List<String> CACHE = new ArrayList<>();
```

4. **静态 ThreadLocal 用完后及时 remove**

---

## 10. 常见面试题详解

### Q1：为什么静态方法不能调用非静态方法？

**答：**
静态方法属于类，在类加载后即可调用，此时可能还没有创建任何对象。而非静态方法属于对象实例，调用时需要隐式的 `this` 引用来确定操作哪个对象。静态方法没有 `this` 引用，因此无法调用非静态方法。

### Q2：static 变量存储在哪里？

**答：**
JDK 7 及之前存储在永久代（PermGen）；JDK 8 及之后存储在元空间（MetaSpace），使用本地内存，不再受 JVM 堆内存大小限制。

### Q3：静态代码块、构造代码块、构造方法的执行顺序是什么？

**答：**

```
父类静态代码块 → 子类静态代码块 → 父类构造代码块 → 父类构造方法 → 子类构造代码块 → 子类构造方法
```

静态代码块只执行一次，构造代码块每次创建对象都执行。

### Q4：静态方法可以被重写吗？

**答：**
不可以。静态方法可以被继承和隐藏（hide），但不能被重写（override）。调用时由编译时类型决定，不具备多态性。

### Q5：static 和 final 可以一起用吗？有什么区别？

**答：**
可以。`static final` 表示"类级别的常量"，所有对象共享且不可修改。`static` 强调共享，`final` 强调不可变。

### Q6：为什么 main 方法是 static 的？

**答：**
JVM 调用 `main` 方法时，还没有创建任何对象。如果 `main` 不是静态的，JVM 就需要先创建对象才能调用，而创建对象又需要 `main` 方法作为入口，形成循环依赖。因此 `main` 必须是静态的。

### Q7：静态内部类和普通内部类的区别？

**答：**
- 静态内部类不依赖外部类实例，普通内部类依赖外部类实例。
- 静态内部类不能访问外部类非静态成员，普通内部类可以。
- 静态内部类不会持有外部类引用，普通内部类会，使用不当可能导致内存泄漏。

### Q8：静态导入有什么好处和坏处？

**答：**
好处是可以省略类名，代码更简洁；坏处是过度使用会降低可读性，并且可能引发命名冲突。

---

## 11. 总结

### 11.1 核心要点

- `static` 表示"属于类"，实现共享和类级别访问。
- 可修饰：**变量、方法、代码块、内部类**，还可以用于**静态导入**。
- 静态成员在类加载时初始化，生命周期与类相同。
- 静态方法不能访问非静态成员，不能使用 `this` 和 `super`。
- 静态方法可以被继承和隐藏，但不能被重写。

### 11.2 典型代码模板

```java
// 工具类
public final class Utils {
    private Utils() {}  // 禁止实例化
    
    public static void helper() {
        // ...
    }
}

// 常量类
public final class Constants {
    public static final String NAME = "MyApp";
}

// 单例模式
public class Singleton {
    private static class Holder {
        private static final Singleton INSTANCE = new Singleton();
    }
    
    private Singleton() {}
    
    public static Singleton getInstance() {
        return Holder.INSTANCE;
    }
}
```

### 11.3 一句话总结

> **`static` 让成员脱离对象实例，归属于类本身，是实现共享数据、工具方法和类级初始化的关键机制。**
