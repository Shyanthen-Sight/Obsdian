
> **适用对象**：学习 Java 面向对象基础（封装、继承）的学生
> **题目总量**：12 道选择题 + 8 道判断题 + 6 道代码分析题 + 5 道综合应用题，共 31 题
> **使用建议**：先独立完成题目，再对照文末「参考答案与详细解析」批改；每道题的解析中都点明了对应的核心考点。
> 难度标记：🟢 基础 ｜ 🟡 进阶 ｜ 🔴 挑战

---

## 一、知识回顾：四种访问修饰符

| 访问修饰符 | 同类 | 同包 | 不同包子类 | 任意类 |
|:---:|:---:|:---:|:---:|:---:|
| `private` | ✅ | ❌ | ❌ | ❌ |
| 默认（包私有，不写） | ✅ | ✅ | ❌ | ❌ |
| `protected` | ✅ | ✅ | ✅（仅限通过继承访问） | ❌ |
| `public` | ✅ | ✅ | ✅ | ✅ |

**权限从大到小**：`public` > `protected` > 默认（包私有）> `private`

**两个关键补充规则**：
1. **顶级类**（非内部类）只能用 `public` 或默认两种访问级别；
2. **方法重写时不能降低可见性**（父类 `public` → 子类必须 `public`；父类 `protected` → 子类可为 `protected` 或 `public`）。

---

## 二、选择题

### 第 1 题（单选）🟢
顶级类（top-level class，非内部类）可以使用的访问修饰符是？

- A. 只能使用 `public`
- B. `public` 和默认（包私有）
- C. `public`、`protected` 和默认
- D. 四种都可以

### 第 2 题（单选）🟢
类的成员（字段、方法）不加任何访问修饰符时，默认访问级别是？

- A. `public`
- B. `private`
- C. `protected`
- D. 包私有（package-private，仅同包可见）

### 第 3 题（单选）🟢
关于 `protected` 修饰符，下列说法**正确**的是？

- A. 只能被同一包内的类访问
- B. 只能被子类访问
- C. 可被同一包内的所有类访问，也可被不同包中的子类通过继承访问
- D. 任何类都可以访问

### 第 4 题（单选）🟡
父类 `A` 有一个 `protected` 成员 `x`，子类 `B` 与 `A` 不在同一个包中。以下哪种访问方式**正确**？

```java
// Father.java  包 com.demo.p1
package com.demo.p1;

public class Father {
    protected int money = 100;
}
```

```java
// Son.java  包 com.demo.p2
package com.demo.p2;

import com.demo.p1.Father;

public class Son extends Father {
    public void test() {
        System.out.println(this.money);    // ①
        Father f = new Father();
        System.out.println(f.money);       // ②
    }
}
```

- A. 只有 ① 正确
- B. 只有 ② 正确
- C. ① 和 ② 都正确
- D. ① 和 ② 都错误

### 第 5 题（多选）🟡
以下哪些访问修饰符可以用于修饰**成员内部类**（非顶级类）？

- A. `private`
- B. `protected`
- C. `public`
- D. 默认（包私有）

### 第 6 题（单选）🟡
关于接口（interface），下列说法**错误**的是？

- A. 接口中的方法默认是 `public abstract`
- B. 接口中的字段默认是 `public static final`
- C. 实现类实现接口方法时必须使用 `public` 修饰
- D. 实现类实现接口方法时可以省略 `public`（即默认为包私有）

### 第 7 题（多选）🟡
关于**构造方法**的访问修饰符，下列说法正确的有？

- A. `private` 构造方法可以实现单例模式
- B. `protected` 构造方法可以被不同包中的子类通过 `super()` 调用
- C. 未声明任何构造方法时，编译器生成的默认构造方法访问级别与类相同
- D. 构造方法不能使用 `static` 或 `final` 修饰

### 第 8 题（单选）🟢
以下访问修饰符的访问范围从大到小排列，**正确**的是？

- A. `public` > `protected` > `private` > 默认
- B. `public` > 默认 > `protected` > `private`
- C. `public` > `protected` > 默认 > `private`
- D. `protected` > `public` > 默认 > `private`

### 第 9 题（多选）🟡
关于**方法重写**（override）中访问修饰符的规则，下列说法正确的有？

- A. 子类重写方法的访问级别不能低于父类方法
- B. 父类方法是 `public`，子类可以重写为 `protected`
- C. 父类方法是 `protected`，子类可以重写为 `public`
- D. 父类方法是 `private`，子类可以"重写"它

### 第 10 题（单选）🟡
关于**抽象方法**的访问修饰符，下列说法**正确**的是？

- A. 抽象方法可以用 `private` 修饰
- B. 抽象方法可以用 `final` 修饰
- C. 抽象方法可以用 `static` 修饰
- D. 抽象方法不能用 `private`、`static`、`final` 修饰，因为需要被子类重写实现

### 第 11 题（单选）🟢
关于**局部变量**，下列说法正确的是？

- A. 局部变量可以用 `private` 修饰
- B. 局部变量不能使用任何访问修饰符修饰
- C. 局部变量可以用 `public` 修饰
- D. 局部变量默认是包私有

### 第 12 题（多选）🟡
关于 `private` 修饰符，下列说法正确的有？

- A. `private` 成员只能在本类内部访问
- B. `private` 成员不会被继承，子类对象中不存在该成员
- C. 同一个类的不同对象之间，可以互相访问对方的 `private` 成员
- D. `private` 构造方法可以防止外部直接创建对象

---

## 三、判断题

请判断下列说法的对错，**错误的说法要说明原因**。

### 第 13 题 🟢
`protected` 成员可以被任何包中的任何类访问。

### 第 14 题 🟡
`private` 方法不能被重写；但子类中定义同名同参的方法，只是定义了一个"新方法"（隐藏），不构成重写。

### 第 15 题 🟢
一个源文件中可以声明多个 `public` 顶级类。

### 第 16 题 🟡
同一个类的静态方法中，可以通过对象引用访问该类的 `private` 实例字段。

### 第 17 题 🟢
父类方法是 `public`，子类重写时可以改为包私有（不写修饰符）。

### 第 18 题 🟢
接口中声明的字段，即使不写任何修饰符，也是 `public static final`。

### 第 19 题 🟡
构造方法不能用 `private` 修饰，否则永远无法创建该类的对象。

### 第 20 题 🟢
两个类在同一个包中，其中一个类的包私有（默认级别）方法可以被另一个类调用。

---

## 四、代码分析题

请判断下列代码**能否编译通过**；若能，写出运行结果（如有）；若不能，指出错误位置并说明原因。

### 第 21 题 🟡（跨包访问 protected）

```java
// Father.java  包 com.demo.p1
package com.demo.p1;

public class Father {
    protected int money = 100;
    public void show() {
        System.out.println("Father.show()");
    }
}
```

```java
// Son.java  包 com.demo.p2
package com.demo.p2;

import com.demo.p1.Father;

public class Son extends Father {
    public void test() {
        System.out.println(money);    // ① 能编译吗？
        Father f = new Father();
        System.out.println(f.money);  // ② 能编译吗？
    }
}
```

**问题**：①、② 两处能否编译通过？

### 第 22 题 🟡（跨包访问 private）

```java
// A.java  包 com.demo.p1
package com.demo.p1;

public class A {
    private String name = "A";
    protected void print() {
        System.out.println(name);
    }
}
```

```java
// B.java  包 com.demo.p2
package com.demo.p2;

import com.demo.p1.A;

public class B extends A {
    public void test() {
        print();               // ① 能编译吗？
        System.out.println(name);   // ② 能编译吗？
    }
}
```

**问题**：①、② 两处能否编译通过？

### 第 23 题 🔴（private 的"类级别"访问控制）

```java
// Person.java  包 com.demo.p1
package com.demo.p1;

public class Person {
    private int age;

    public Person(int age) {
        this.age = age;
    }

    public boolean isOlderThan(Person other) {
        return this.age > other.age;   // ① 能访问 other 的 private 字段吗？
    }

    public int getAge() {
        return age;
    }
}
```

**问题**：① 处访问另一个对象 `other` 的 `private` 字段 `age`，能否编译通过？为什么？

### 第 24 题 🟡（重写不能降低可见性）

```java
// Parent.java  包 com.demo.p1
package com.demo.p1;

public class Parent {
    public void method() {
        System.out.println("Parent.method");
    }
}
```

```java
// Child.java  包 com.demo.p2
package com.demo.p2;

import com.demo.p1.Parent;

public class Child extends Parent {
    void method() {   // ① 能编译吗？
        System.out.println("Child.method");
    }
}
```

**问题**：该代码能否编译通过？

### 第 25 题 🟡（同包访问 protected / private）

```java
// Base.java  包 com.demo.p1
package com.demo.p1;

public class Base {
    protected int num = 10;
    private String secret = "secret";

    public void showSecret() {
        System.out.println(secret);
    }
}
```

```java
// SamePackage.java  同样是 com.demo.p1 包
package com.demo.p1;

public class SamePackage {
    public static void main(String[] args) {
        Base b = new Base();
        System.out.println(b.num);      // ① 能编译吗？
        System.out.println(b.secret);   // ② 能编译吗？
        b.showSecret();                 // ③ 能编译吗？
    }
}
```

**问题**：①、②、③ 三处能否编译通过？③ 若能，运行结果是什么？

### 第 26 题 🟡（单例模式与私有构造）

```java
// Singleton.java
public class Singleton {
    private static Singleton instance;

    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {
            instance = new Singleton();
        }
        return instance;
    }
}
```

```java
// Test.java
public class Test {
    public static void main(String[] args) {
        Singleton s = new Singleton();   // ① 能编译吗？
        Singleton t = Singleton.getInstance();  // ② 能编译吗？
    }
}
```

**问题**：
1. ① 处能否编译通过？
2. ② 处能否编译通过？
3. 为什么 `Singleton` 的构造方法要声明为 `private`？

---

## 五、综合应用题

### 第 27 题 🟡（封装设计）
设计一个银行账户类 `BankAccount`，要求：
1. 余额 `balance` 不能被外部直接修改，只能通过方法操作；
2. 提供 `deposit(double)` 存款、`withdraw(double)` 取款、`getBalance()` 查询余额三个方法；
3. 取款时若余额不足，应给出提示而不是扣除。

请写出完整代码，并说明为什么 `balance` 要用 `private`。

### 第 28 题 🟢（权限排序）
请将四种访问级别按权限从小到大排列，并结合实际场景说明什么是"最小权限原则"、什么时候该用它。

### 第 29 题 🟡（接口实现为什么必须是 public）
为什么实现类实现接口方法时**必须**使用 `public` 修饰？请从"接口方法的默认修饰符"和"重写可见性规则"两个角度解释。

### 第 30 题 🟡（选择合适的修饰符）
对于以下需求，分别选择最合适的访问修饰符（`private` / 默认 / `protected` / `public`）并说明理由：
1. 一个类内部的辅助方法，只允许本类调用；
2. 类的常量，希望任何地方都能直接使用；
3. 一个字段希望同包的类能直接访问，但包外（包括子类）不能访问；
4. 一个模板方法希望子类可以重写/调用，但不希望包外的其他类调用。

### 第 31 题 🔴（private 方法与重写的辨析）
父类 `Base` 中有一个 `private void hello()` 方法，子类 `Child` 中定义了一个**同名同参**的 `public void hello()` 方法。请问：
1. 子类的方法是否构成对父类方法的**重写**（override）？
2. 以下代码的输出是什么？

```java
public class Base {
    private void hello() {
        System.out.println("Base.hello");
    }
    public void call() {
        hello();   // 这里调用的是哪个 hello？
    }
}

public class Child extends Base {
    public void hello() {
        System.out.println("Child.hello");
    }

    public static void main(String[] args) {
        Base b = new Child();
        b.call();
    }
}
```

---

# 参考答案与详细解析

## 第二部分：选择题

### 第 1 题 答案：**B**
**解析**：顶级类（非内部类）只能使用 `public` 或默认（包私有）两种访问级别。`protected` 和 `private` 只能用于修饰类的成员，包括成员内部类（见第 5 题）。`public` 类要求文件名与类名一致，且一个源文件只能有一个 `public` 顶级类。

### 第 2 题 答案：**D**
**解析**：不加任何访问修饰符的成员默认是**包私有**（package-private）：同一包内的所有类都可以访问，包外的类即使有继承关系也不能直接访问。注意不要与 `protected` 混淆——默认级别**没有**"跨包子类可访问"这一条。

### 第 3 题 答案：**C**
**解析**：`protected` 的访问范围 = **同包所有类** + **不同包中的子类（通过继承）**。A 漏掉了跨包子类，B 漏掉了同包非子类，D 是 `public` 的特征。

### 第 4 题 答案：**A**
**解析**：这是 `protected` 最易错的考点。跨包场景下，子类 `Son` 访问父类 `Father` 的 `protected` 成员 `money` 时，**只能通过继承链访问**（`this.money` 或 `Son` 类型引用），不能通过 `Father` 类型的引用访问（`f.money` 属于"访问 Father 对象自己的 protected 成员"，Son 对此没有权限）。
**对比记忆**：如果 `Son` 和 `Father` 在**同一个包**中，① 和 ② 都能通过——因为同包任意类都可直接访问 `protected` 成员。

### 第 5 题 答案：**A、B、C、D（全选）**
**解析**：成员内部类是外部类的**成员**，因此四种访问级别都可用。这与顶级类（只能用 `public` / 默认）形成对比。例如 `private` 内部类只能在外部的该类内部创建，常用于隐藏实现细节。

### 第 6 题 答案：**D**
**解析**：接口方法隐式是 `public abstract`，实现类重写时**不能降低可见性**，因此必须写 `public`。A、B 是接口成员默认修饰符的标准结论（字段隐式 `public static final`），C 正确。注意：D 中的"default"指的是访问级别，与 Java 8 的 `default` 方法（接口中带方法体的默认方法）是两回事，后者仍须是 `public`。

### 第 7 题 答案：**A、B、C、D（全选）**
**解析**：
- A：`private` 构造方法禁止外部 `new`，配合静态工厂方法即可实现单例（见第 26 题）；
- B：跨包子类在构造方法中可以通过 `super(...)` 调用父类的 `protected` 构造方法（继承访问）；
- C：若类中没有声明任何构造方法，编译器会生成一个无参默认构造方法，其访问级别**与类相同**（类 `public` → 构造 `public`；类包私有 → 构造包私有）。注意：只要手动声明了任意构造方法，编译器就不再生成默认构造；
- D：构造方法不允许 `static`、`final`、`abstract`、`synchronized`、`native`、`strictfp` 修饰。

### 第 8 题 答案：**C**
**解析**：访问范围从大到小：`public`（所有地方）> `protected`（同包 + 跨包子类）> 默认（仅同包）> `private`（仅本类）。注意 `protected` 的范围**大于**默认级别，因为它额外包含了跨包子类的继承访问。

### 第 9 题 答案：**A、C**
**解析**：重写规则的铁律是"**只升不降**"：子类重写方法的访问级别必须**大于等于**父类方法。
- A 正确，这是规则本身；
- B 错误，`public` 降为 `protected` 属于降低可见性，编译报错；
- C 正确，`protected` 升为 `public` 是允许的（扩大可见性）；
- D 错误，`private` 方法对子类不可见，**不存在重写**，子类写同名方法只是"新方法"（隐藏），见第 31 题。

### 第 10 题 答案：**D**
**解析**：抽象方法必须被子类重写实现，因此不能用 `private`（子类看不到）、`static`（静态方法不能重写）、`final`（禁止重写）修饰。A、B、C 均会导致编译错误：`private abstract` / `static abstract` / `final abstract` 组合非法。

### 第 11 题 答案：**B**
**解析**：访问修饰符（`public` / `protected` / `private`）只能用于修饰类、成员变量、成员方法等"类级别"元素；**局部变量**是方法内部的定义，作用域天然限于方法块内，不允许也不需要使用访问修饰符。C 的 `public` 和 A 的 `private` 修饰局部变量都会编译报错。

### 第 12 题 答案：**A、C、D**
**解析**：
- A 正确，`private` 仅本类可访问；
- B **错误**，这是常见误区：`private` 成员会被继承到子类对象中（对象内存里存在），只是子类的代码无法**直接**访问，可通过父类的 `public` / `protected` 方法间接访问（见第 22 题）；
- C 正确，`private` 的访问控制是**类级别**而非**对象级别**：同一个类的任何方法，都可以访问该类的任意实例的 `private` 成员（见第 23 题）；
- D 正确，`private` 构造方法使外部无法 `new`，是单例模式的核心手段。

## 第三部分：判断题

### 第 13 题 答案：**错误（×）**
`protected` 只能被**同包所有类**和**不同包中的子类**（通过继承）访问，普通的不同包类无法访问。任意类都能访问是 `public` 的特征。

### 第 14 题 答案：**正确（√）**
`private` 方法对子类不可见，不存在重写。子类定义同名同参方法只是定义了一个独立的新方法，父类方法被"隐藏"。可加 `@Override` 注解验证——子类方法上加该注解会编译报错（因为并未重写任何父类方法）。

### 第 15 题 答案：**错误（×）**
一个源文件**最多只能有一个** `public` 顶级类，且该类名必须与文件名一致。可以有多个包私有（默认级别）顶级类，但它们不能与 `public` 类同名。

### 第 16 题 答案：**正确（√）**
`private` 是"类级别"控制：类中的**任何方法**（包括静态方法）都可以通过该类的对象引用访问其 `private` 实例字段。注意区别：静态方法中不能直接使用 `this.字段`（静态上下文没有 `this`），但可以通过 `new 类().字段` 或参数传入的对象访问。

### 第 17 题 答案：**错误（×）**
方法重写**不能降低可见性**。父类方法是 `public`，子类重写时必须也是 `public`，写成包私有（默认级别）会编译报错：`attempting to assign weaker access privileges`。

### 第 18 题 答案：**正确（√）**
接口中的字段隐式是 `public static final`（常量），即使不写修饰符也一样。因此接口字段必须在声明时初始化，且一旦赋值不可修改。

### 第 19 题 答案：**错误（×）**
构造方法**可以**用 `private` 修饰（如单例模式）。`private` 构造只是阻止**外部**创建对象，类**内部**仍然可以 `new`（如单例的 `getInstance()` 方法内部 `new Singleton()`）。设计上还常配合静态工厂方法使用。

### 第 20 题 答案：**正确（√）**
包私有（默认级别）的成员可以被**同一包内**的所有类访问，这是默认访问级别的定义。

## 第四部分：代码分析题

### 第 21 题 答案：① 能编译；② **不能**编译。
**解析**：`Son` 与 `Father` 不在同一包。跨包场景下，子类只能通过**继承链**访问父类的 `protected` 成员：
- ① `this.money` 访问的是继承来的成员，合法；
- ② `f.money` 通过 `Father` 类型的引用访问，属于访问"Father 对象自身的 protected 成员"，`Son` 没有该权限，编译报错。
**记忆口诀**：跨包的 `protected`，"自己继承的可以拿，父类对象的不能碰"。

### 第 22 题 答案：① 能编译；② **不能**编译。
**解析**：
- ① `print()` 是 `protected` 方法，子类 `B` 通过继承访问，合法；
- ② `name` 是 `private` 字段，**对子类不可见**，即使通过继承也访问不到，编译报错。
**结论**：`private` 成员"被继承但不可直接访问"——要访问只能通过父类提供的 `public` / `protected` 方法（如 `print()` 内部能访问 `name`）。

### 第 23 题 答案：① **能编译**。
**解析**：`private` 的访问控制是**类级别**的：`isOlderThan` 方法位于 `Person` 类内部，因此可以访问**任何** `Person` 对象的 `private` 字段，包括参数传入的 `other`。这是合法且常见的写法（如比较两个对象时访问对方的私有属性）。限制只发生在"**类与类之间**"——其他类（包括子类）无法直接访问 `Person` 的 `private` 成员。

### 第 24 题 答案：**不能编译**。
**解析**：`Child` 重写 `Parent.method()` 时，把 `public` 降为了包私有（默认级别），违反"重写不能降低可见性"规则，编译报错。且 `Child` 与 `Parent` 不在同一包，即使都在同一包也一样会报错。修复方式：把 `Child.method()` 声明为 `public`。

### 第 25 题 答案：① 能编译；② **不能**编译；③ 能编译，输出 `secret`。
**解析**：`SamePackage` 与 `Base` 在**同一个包** `com.demo.p1`：
- ① `b.num` 是 `protected`，同包任何类都可直接访问，合法；
- ② `b.secret` 是 `private`，仅 `Base` 类内部可访问，即使同包也不可以，编译报错；
- ③ `showSecret()` 是 `public`，可以调用；方法内部处于 `Base` 类中，可以访问自己的 `private` 字段，所以输出 `secret`。
**对比第 22 题**：同包能访问 `protected`，但无论同包还是跨包都**不能**直接访问 `private`——`private` 是唯一不受"包"影响的修饰符。

### 第 26 题 答案：
1. ① **不能编译**——`Singleton` 的构造方法是 `private`，只能在类内部调用，外部 `new Singleton()` 编译报错；
2. ② **能编译**——`getInstance()` 是 `public static` 方法，外部可以调用；方法内部在 `Singleton` 类中，可以访问 `private` 构造方法；
3. **设计意图**：`private` 构造方法阻止外部随意创建对象，保证整个程序只有**一个** `Singleton` 实例（单例模式）。配合 `static` 实例字段和静态工厂方法 `getInstance()` 实现全局唯一实例，避免重复创建带来的资源浪费和状态不一致。

## 第五部分：综合应用题

### 第 27 题 参考代码：

```java
public class BankAccount {
    private double balance;   // 私有字段：外部无法直接访问

    public BankAccount(double initialBalance) {
        this.balance = initialBalance;
    }

    public void deposit(double amount) {
        if (amount > 0) {
            balance += amount;
            System.out.println("存入 " + amount + "，当前余额：" + balance);
        } else {
            System.out.println("存款金额必须大于 0");
        }
    }

    public void withdraw(double amount) {
        if (amount > 0 && amount <= balance) {
            balance -= amount;
            System.out.println("取出 " + amount + "，当前余额：" + balance);
        } else {
            System.out.println("余额不足或金额非法，取款失败");
        }
    }

    public double getBalance() {
        return balance;
    }
}
```

**解析**：`balance` 用 `private` 修饰，外部代码**无法直接读写**余额，只能通过 `deposit` / `withdraw` / `getBalance` 三个 `public` 方法操作。这样做的意义（**封装**，encapsulation）：
1. **数据安全**：外部无法绕过校验直接改余额（如改成负数）；
2. **业务规则内聚**：取款校验（余额不足拒绝）集中在类内部，外部调用者无需关心；
3. **可维护性**：以后要加利率、手续费等逻辑，只需修改类内部，不影响外部调用代码。

### 第 28 题 参考解答：
**权限从小到大**：`private` < 默认（包私有）< `protected` < `public`

**最小权限原则**：在满足功能需求的前提下，尽量使用**访问范围最小**的修饰符——能用 `private` 就不用默认，能用默认就不用 `protected`，能用 `protected` 就不用 `public`。

**使用场景**：
- 不希望外部看到的内部实现细节（辅助方法、缓存字段）→ `private`；
- 仅供本包内部协作使用 → 默认级别；
- 需要开放给子类扩展、但不希望被任意类调用 → `protected`；
- 真正对外的 API 接口 → `public`。

**好处**：减少类的"暴露面"，降低耦合，避免外部误用，同时保留后续修改内部实现的自由度（对外可见性不变则调用方无需改动）。

### 第 29 题 参考解答：
**角度一：接口方法的默认修饰符**。接口中的方法隐式是 `public abstract`——即使不写 `public`，编译后也是 `public`。因此接口方法本身是 `public` 的。

**角度二：重写可见性规则**。实现类实现接口方法，本质上是**重写**该抽象方法，而重写规则要求"**不能降低可见性**"：`public` 方法只能被重写为 `public`。所以实现类的方法必须是 `public`。

**本质理解**：接口定义的是一份"对外契约"——任何拿到该接口引用的人都能调用其方法。若实现方法不是 `public`，契约就名存实亡，所以语言层面强制 `public`。

### 第 30 题 参考解答：
1. **辅助方法** → `private`。仅本类内部逻辑需要，对外完全隐藏，防止误用，同时方便以后重构（方法名、实现随便改，不影响外部）。
2. **公共常量** → `public static final`。需要任何地方直接使用（如 `Math.PI`、`Color.RED`），`static final` 保证全局一份且不可修改。注意：接口中的常量连 `public static final` 都可以省略（隐式）。
3. **同包可访问的字段** → 默认（包私有）。同包类直接访问，包外（包括子类）不可访问。注意：若还要允许跨包子类访问，则要用 `protected`。
4. **模板方法** → `protected`。`protected` 的范围恰好是"同包类 + 跨包子类"，既给了子类重写/调用的权限，又对包外的无关类关闭了访问通道，是"扩展点"设计的标准做法。

### 第 31 题 参考解答：
1. **不构成重写**。`Base.hello()` 是 `private`，对子类不可见，子类的 `public void hello()` 只是一个**同名新方法**（隐藏了父类的私有方法），与父类方法毫无关系。验证方法：在 `Child.hello()` 上加 `@Override` 注解会编译报错。

2. **输出结果：`Base.hello`**。
**解析**：调用链是 `b.call()` → 方法内部执行 `hello()`。关键在于 `call()` 方法**定义在 `Base` 类中**，其中的 `hello()` 调用解析为 `Base` 类的私有方法——而私有方法**不参与多态**（不存在重写，也就没有动态绑定），所以无论 `b` 的实际类型是什么，`call()` 里的 `hello()` 都绑定到 `Base.hello()`，输出 `Base.hello`。
**对比**：若把 `Base.hello()` 改为 `protected` 或 `public`，子类方法构成重写，调用将发生动态绑定，`b.call()` 输出 `Child.hello`——这正是"私有方法无多态"这一特性的直接体现。

---

## 附：常见误区速查表

| 误区 | 正解 |
|:---|:---|
| `protected` 只能被子类访问 | 同包**所有类**都可访问，跨包才要求子类 |
| `private` 成员不会被继承 | 会被继承（对象中存在），只是子类**不能直接访问** |
| 子类可以把父类 `public` 方法重写为包私有 | 重写只允许**扩大**可见性，不允许缩小 |
| 实现接口方法可以不写 `public` | 接口方法隐式 `public`，实现必须 `public` |
| 访问修饰符可以用在局部变量上 | 局部变量不允许任何访问修饰符 |
| 一个文件可以有多个 `public` 类 | 最多一个，且类名 = 文件名 |
| 子类写同名方法就是重写父类 `private` 方法 | `private` 方法不可重写，只是"隐藏"，无多态 |
| `private` 构造方法 = 永远无法创建对象 | 只是外部不能 `new`，类内部仍可创建（单例） |
