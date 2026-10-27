> **注意**：Java 中的关键字是 **super**（父类的引用），而 `supper` 在英语中是“晚餐”的意思。建议将本文件重命名为 `super关键字.md`。

# Java `super` 关键字详解

`super` 是一个引用关键字，用于在子类中表示对**直接父类对象**的引用。它主要解决子类和父类成员命名冲突的问题，并用于调用父类的构造方法。

---

## 一、三种核心用法

### 1. 访问父类的成员变量

当子类和父类定义了==**同名成员变量**时，使用 `super.变量名` 访问父类中的变量。==

```java
class Animal {
    String name = "动物";
}

class Dog extends Animal {
    String name = "狗狗";

    void printName() {
        System.out.println(name);       // 输出：狗狗（子类成员）
        System.out.println(super.name); // 输出：动物（父类成员）
    }
}
```

---

### 2. 调用父类的方法

当==子类**重写了父类方法**时，可以通过 `super.方法名()` 调用父类的原始实现==。

```java
class Animal {
    void speak() {
        System.out.println("动物发出声音");
    }
}

class Dog extends Animal {
    @Override
    void speak() {
        super.speak();          // 先调用父类方法
        System.out.println("汪汪汪");
    }
}
```

> 典型应用：在重写 `toString()`、`equals()` 或自定义业务方法时，保留父类的通用逻辑。

---

### 3. 调用父类的构造方法

使用 `super(参数)` 调用父类的构造方法。

```java
class Animal {
    String name;

    Animal(String name) {
        this.name = name;
    }
}

class Dog extends Animal {
    int age;

    Dog(String name, int age) {
        super(name);   // 必须放在子类构造方法的第一行
        this.age = age;
    }
}
```

---

## 二、重要规则

### 1. `super()` 必须在构造方法第一行

```java
class Cat extends Animal {
    Cat() {
        super("小猫");   // 必须是第一条语句
        // 其他代码...
    }
}
```

如果父类没有无参构造方法，子类构造方法**必须显式调用**父类的有参构造方法，否则编译报错。

---

### 2. 编译器会自动插入 `super()`

如果子类构造方法中没有写 `super()`，编译器会自动在第一行插入 `super()`（调用父类无参构造）。

```java
class Dog extends Animal {
    Dog() {
        // 编译器自动补全: super();
    }
}
```

因此，如果父类只有有参构造而没有无参构造，子类必须显式写 `super(参数)`。

---

### 3. `super` 和 `this` 不能同时出现在同一个构造方法中

因为 `super()` 和 `this()` 都必须放在构造方法的第一行，所以二者不能共存。

```java
class Example {
    Example() {
        this(10);      // 调用本类其他构造
        // super();     // 编译错误！不能同时存在
    }

    Example(int x) {
        // 编译器自动插入 super();
    }
}
```

---

## 三、`super` vs `this`

| 特性 | `super` | `this` |
|------|---------|--------|
| 含义 | 对当前对象的父类部分的引用 | 对当前对象自身的引用 |
| 访问成员 | `super.name` 访问父类成员 | `this.name` 访问当前类成员 |
| 调用方法 | `super.method()` 调用父类方法 | `this.method()` 调用当前类方法 |
| 调用构造 | `super(参数)` 调用父类构造 | `this(参数)` 调用本类其他构造 |
| 第一行要求 | 构造方法中必须是第一行 | 构造方法中必须是第一行 |
| 使用次数 | 一个构造方法中最多一次 | 一个构造方法中最多一次 |

---

## 四、Object 类：所有类的终极父类

如果一个类没有显式继承任何类，它会默认继承 `java.lang.Object`。

```java
class Person { }
// 等价于
class Person extends Object { }
```

因此，所有类的构造方法最终都会通过 `super()` 链式调用到 `Object` 的构造方法。对象创建时的构造顺序为：

1. 分配内存
2. 递归调用父类构造方法（从 Object 开始）
3. 执行子类构造方法

```java
class A extends Object { }
class B extends A { }
class C extends B { }

new C();  // 构造顺序：Object → A → B → C
```

---

## 五、典型应用场景

### 场景 1：调用父类被重写的方法

```java
class Rectangle {
    void draw() {
        System.out.println("绘制矩形");
    }
}

class Square extends Rectangle {
    @Override
    void draw() {
        super.draw();
        System.out.println("绘制正方形");
    }
}
```

### 场景 2：父类私有成员通过父类方法访问

```java
class Person {
    private String idCard;

    Person(String idCard) {
        this.idCard = idCard;
    }

    String getIdCard() {
        return idCard;
    }
}

class Student extends Person {
    String name;

    Student(String idCard, String name) {
        super(idCard);
        this.name = name;
    }

    void show() {
        // System.out.println(super.idCard); // 错误！private 不可直接访问
        System.out.println(super.getIdCard()); // 正确，通过父类公共方法访问
        System.out.println(this.name);
    }
}
```

### 场景 3：多层继承中使用 super

`super` 只能访问**直接父类**的成员。如果需要访问爷爷类的成员，只能通过父类间接访问。

```java
class Grandpa {
    int age = 80;
}

class Father extends Grandpa {
    int age = 50;
}

class Son extends Father {
    int age = 20;

    void print() {
        System.out.println(age);       // 20
        System.out.println(super.age); // 50，直接父类 Father 的 age
        // 不能直接访问 Grandpa 的 age，除非 Father 暴露出来
    }
}
```

---

## 六、常见面试题

### Q1：`super()` 和 `this()` 能同时出现吗？

**不能**。因为它们都必须位于构造方法的第一行，位置冲突。

---

### Q2：子类构造方法中没有写 `super()`，会调用父类构造吗？

**会**。编译器会自动插入 `super()`，调用父类的无参构造。

---

### Q3：父类构造方法可以调用子类重写的方法吗？

**可以调用，但执行的是子类重写后的版本**（多态性）。这可能导致子类还未初始化完成就被调用，应谨慎使用。

```java
class Parent {
    Parent() {
        init(); // 实际调用子类的 init()
    }
    void init() { }
}

class Child extends Parent {
    int x = 10;
    @Override
    void init() {
        System.out.println(x); // 可能输出 0，因为 x 还未初始化
    }
}
```

---

### Q4：`super` 和父类对象是一回事吗？

**不是**。`super` 是子类对象中对父类部分的引用，本质上还是同一个子类对象，只是访问范围限定为父类可见的成员。

---

## 七、易错点总结

| 错误 | 说明 |
|------|------|
| 用 `super` 调用父类 `private` 成员 | `private` 成员只能在定义它的类中访问 |
| 在静态方法中使用 `super` | `super` 代表对象引用，不能在 `static` 上下文中使用 |
| 父类只有有参构造，子类不调用 | 编译报错，必须显式 `super(参数)` |
| 试图通过 `super` 访问爷爷类成员 | `super` 只指向直接父类 |

---

## 八、一句话总结

> `super` 是子类对象对其**直接父类部分**的引用，用于访问父类成员、调用父类方法以及在子类构造中调用父类构造方法。
