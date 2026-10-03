# this 关键字

## 1. 基本含义

`this` 是 Java 中的一个==**引用变量**==（reference variable），它指向==**当前对象本身**==。也就是说，在类的非静态方法、构造器或初始化代码块中，`this` 代表调用该方法/构造器的那个对象实例。

从底层角度看，每个非静态方法在 JVM 调用时，除了显式声明的参数外，还会隐式接收一个指向当前对象的引用参数，这个引用就是 `this`。因此：

- 非静态方法必然依赖于某个对象才能调用；
- ==通过 `this` 可以访问当前对象的所有成员（字段、方法、构造器）==。

> **注意**：`this` 不能在 **static 方法** 或 **static 代码块** 中使用，因为==静态成员属于类，不属于某个具体对象==，不存在"当前对象"的概念。

```java
public class Demo {
    public void show() {
        System.out.println(this); // 打印当前对象的引用地址
    }

    public static void main(String[] args) {
        Demo d = new Demo();
        d.show(); // 输出类似：Demo@6d06d69c
    }
}
```

---

## 2. 常见使用场景

### 2.1 区分成员变量与局部变量（最常用）

当方法参数或局部变量与类的成员变量同名时，==使用 `this.变量名` 显式指代成员变==量。这是 `this` 最常见的用途，主要出现在==构造器和 setter 方法中==。

```java
public class Student {
    private String name;
    private int age;

    public Student(String name, int age) {
        this.name = name; // this.name 指成员变量，name 指形参
        this.age = age;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

==如果没有命名冲突，`this` 可以省略==，编译器会自动识别成员变量：

```java
public void setAge(int age) {
    age = age; // ❌ 错误：两个 age 都指形参，成员变量未被赋值
}

public void setAge(int age) {
    this.age = age; // ✅ 正确
}
```

---

### 2.2 调用当前类的其他构造器（this()）

`this(...)` 可以在构造器中调用本类的另一个构造器，**必须放在构造器的第一行**，且**一个构造器中最多只能出现一次**。

```java
public class Student {
    private String name;
    private int age;

    // 无参构造器：提供默认值
    public Student() {
        this("未知", 18); // 调用下面的双参构造器
    }

    // 单参构造器：指定姓名，年龄默认 18
    public Student(String name) {
        this(name, 18);
    }

    public Student(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

**好处**：

- 避免在多个构造器中重复编写相同的初始化逻辑；
- 集中维护初始化代码，减少出错概率。

> **注意**：`this()` 和 `super()` ==不能同时出现在一个构造器中==，因为它们都要求位于构造器的第一行。如果构造器中没有显式调用 `this()` 或 `super()`，编译器会自动在第一行插入 `super()`（调用父类无参构造器）。

```java
public class Student extends Person {
    public Student() {
        // 编译器默认插入 super();
        this("未知"); // ❌ 报错：this() 必须为第一行
    }
}
```

---

### 2.3 返回当前对象，实现方法链式调用

在方法末尾使用 `return this;` 可以返回当前对象本身，从而支持连续调用多个方法。这种写法在**建造者模式（Builder Pattern）**和**流式 API** 中非常常见。

```java
public class Builder {
    private String partA;
    private String partB;
    private String partC;

    public Builder setPartA(String partA) {
        this.partA = partA;
        return this;
    }

    public Builder setPartB(String partB) {
        this.partB = partB;
        return this;
    }

    public Builder setPartC(String partC) {
        this.partC = partC;
        return this;
    }

    public Product build() {
        return new Product(partA, partB, partC);
    }
}

// 链式调用
Product product = new Builder()
        .setPartA("A")
        .setPartB("B")
        .setPartC("C")
        .build();
```

---

### 2.4 将当前对象作为参数传递

当需要把当前对象传给另一个方法、回调函数或事件处理器时，可以直接使用 `this`。

```java
public class Person {
    private String name;

    public void register(AccountService service) {
        service.createAccount(this); // 将当前 Person 对象传给服务层
    }
}

public class AccountService {
    public void createAccount(Person person) {
        System.out.println("为 " + person + " 创建账户");
    }
}
```

典型应用场景：

- GUI 事件监听：`button.addActionListener(this);`
- 线程启动：`new Thread(this).start();`（当前类实现 `Runnable`）
- 集合注册：`list.add(this);`

---

### 2.5 在内部类中区分外部类对象

当内部类与外部类存在同名成员时，使用 `外部类名.this.成员` 访问外部类成员。

```java
public class Outer {
    private int value = 10;

    class Inner {
        private int value = 20;

        public void print() {
            System.out.println(value);              // 20，内部类成员
            System.out.println(this.value);         // 20，内部类成员
            System.out.println(Outer.this.value);   // 10，外部类成员
        }
    }

    public static void main(String[] args) {
        Outer outer = new Outer();
        Outer.Inner inner = outer.new Inner();
        inner.print();
    }
}
```

对于匿名内部类和局部内部类，同样适用：

```java
public class Outer {
    private String msg = "外部类消息";

    public void show() {
        // 局部内部类
        class Local {
            private String msg = "局部类消息";

            public void print() {
                System.out.println(msg);            // 局部类消息
                System.out.println(Outer.this.msg); // 外部类消息
            }
        }
        new Local().print();
    }
}
```

---

### 2.6 调用当前对象的其他方法（通常可省略）

在同一个类中调用其他非静态方法时，可以显式使用 `this.method()`，但通常可以省略 `this.`。

```java
public class Calculator {
    public int add(int a, int b) {
        return a + b;
    }

    public int addThenDouble(int a, int b) {
        int sum = this.add(a, b); // 等价于 add(a, b)
        return sum * 2;
    }
}
```

在存在方法重写或需要强调当前对象行为时，显式写 `this.` 可以提高代码可读性。

---

## 3. this 与 super 的对比

| 特性    | `this`                         | `super`                          |
| ----- | ------------------------------ | -------------------------------- |
| 指向    | 当前对象本身                         | 当前对象的父类部分                        |
| 访问成员  | `this.field` / `this.method()` | `super.field` / `super.method()` |
| 调用构造器 | `this(...)` 调用本类其他构造器          | `super(...)` 调用父类构造器             |
| 位置要求  | 必须位于构造器第一行                     | 必须位于构造器第一行                       |
| 能否共存  | `this()` 和 `super()` 不能同时出现    | `this()` 和 `super()` 不能同时出现      |
| 使用场景  | 区分同名变量、链式调用、传当前对象              | 访问父类被隐藏/重写的方法或字段                 |

```java
public class Animal {
    protected String name = "动物";

    public Animal(String name) {
        this.name = name;
    }
}

public class Dog extends Animal {
    private String name = "狗狗";

    public Dog() {
        super("动物"); // 调用父类构造器
    }

    public void print() {
        System.out.println(name);       // 狗狗（子类成员）
        System.out.println(this.name);  // 狗狗（子类成员）
        System.out.println(super.name); // 动物（父类成员）
    }
}
```

---

## 4. 使用要点总结

| 场景 | 写法 | 注意点 |
|------|------|--------|
| 访问当前对象的成员变量 | `this.field` | 用于区分同名局部变量 |
| 调用当前对象的方法 | `this.method()` | 通常可省略 |
| 调用本类其他构造器 | `this(...)` | 必须放在构造器第一行，且只能出现一次 |
| 返回当前对象 | `return this;` | 常用于链式调用、建造者模式 |
| 当前对象作为参数 | `someMethod(this)` | 常见于事件回调、注册逻辑 |
| 内部类访问外部类成员 | `Outer.this.field` | 解决命名冲突 |
| 比较当前对象 | `this == other` | 判断是否为同一对象 |

---

## 5. 常见误区与面试题

### 误区 1：在 static 方法中使用 this

```java
public class Demo {
    private int value;

    public static void staticMethod() {
        // System.out.println(this.value); // ❌ 编译错误
    }
}
```

原因：`static` 方法属于类，不依赖于任何对象实例，因此不存在"当前对象"。

### 误区 2：this() 不在第一行

```java
public class Demo {
    public Demo() {
        System.out.println("开始初始化");
        this(10); // ❌ 编译错误：this() 必须是第一条语句
    }

    public Demo(int value) {
        // ...
    }
}
```

### 误区 3：循环调用构造器

```java
public class Demo {
    public Demo() {
        this(10); // 调用 Demo(int)
    }

    public Demo(int value) {
        this();   // ❌ 编译错误：循环调用构造器
    }
}
```

### 面试题 1：以下代码输出什么？

```java
public class ThisDemo {
    int x = 10;

    public void method() {
        int x = 20;
        System.out.println(x);      // ?
        System.out.println(this.x); // ?
    }

    public static void main(String[] args) {
        new ThisDemo().method();
    }
}
```

**答案**：输出 `20` 和 `10`。局部变量 `x` 遮蔽了成员变量 `x`，访问成员变量需要用 `this.x`。

### 面试题 2：this() 和 super() 能否同时存在？

**答案**：不能。因为它们都必须放在构造器的第一行，互相冲突。

### 面试题 3：构造器中没有任何显式调用时，编译器会做什么？

**答案**：编译器会自动在构造器第一行插入 `super()`，即调用父类的无参构造器。如果父类没有无参构造器，则子类构造器必须显式调用父类的其他构造器，否则会编译失败。

---

## 6. 最佳实践

1. **构造器参数与成员变量同名时，使用 `this.field` 赋值**，提高代码可读性和可维护性。
2. **多个构造器有重复逻辑时，使用 `this(...)` 委托给最完整的构造器**，避免代码重复。
3. **设计流式 API 或建造者模式时，使用 `return this;`**，支持链式调用。
4. **在内部类中访问外部类成员时，使用 `Outer.this.field`**，避免歧义。
5. **不要滥用 `this`**，在没有命名冲突且不会提高可读性的情况下，可以省略。
