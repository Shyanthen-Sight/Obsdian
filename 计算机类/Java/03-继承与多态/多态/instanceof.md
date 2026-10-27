# Java instanceof

> `instanceof` 用来在==运行期==判断一个对象是不是某种类型（类、接口、数组），是向下转型前最常用的安全网。

## 1. 作用与语法

```java
对象引用 instanceof 类型
```

结果是一个 `boolean`：

```java
Employee e = new Manager("张三", 2000);

if (e instanceof Manager) {
    System.out.println("这是一个 Manager 对象");
}
```

关键点：

* 判断的是==对象的运行时类型==，不是引用变量的编译时类型；
* `e` 的声明类型是 `Employee`，但实际指向 `Manager`，所以 `e instanceof Manager` 为 `true`；
* `instanceof` 是一个==运算符==，优先级低于关系运算符、高于逻辑运算符，通常直接加括号使用。

## 2. 判断规则

对于 `x instanceof T`，当且仅当下面条件成立时返回 `true`：

1. `x` 不为 `null`；
2. `x` 的实际类型是 `T`，**或者** 实际类型是 `T` 的子类/实现类。

| 表达式 | 结果 | 说明 |
| --- | --- | --- |
| `new Manager() instanceof Manager` | `true` | 类型完全一致 |
| `new Manager() instanceof Employee` | `true` | Manager 是 Employee 的子类 |
| `new Employee() instanceof Manager` | `false` | 父类对象不一定是子类 |
| `new Worker() instanceof Workable` | `true` | Worker 实现了 Workable |
| `null instanceof Employee` | `false` | ==`null` 不是任何类型的实例，也不会抛异常== |
| `new Manager() instanceof Object` | `true` | 所有对象都继承 Object |

```java
class Employee {
    protected String name;
    public Employee(String name) { this.name = name; }
}

class Manager extends Employee {
    public Manager(String name) { super(name); }
}

interface Workable {
    void work();
}

class Worker extends Employee implements Workable {
    public Worker(String name) { super(name); }
    public void work() { System.out.println(name + " 在工作"); }
}
```

```java
public class Demo {
    public static void main(String[] args) {
        Employee e1 = new Manager("张三");
        Employee e2 = new Worker("李四");
        Employee e3 = new Employee("王五");

        System.out.println(e1 instanceof Manager);   // true
        System.out.println(e1 instanceof Employee);  // true
        System.out.println(e3 instanceof Manager);   // false
        System.out.println(e2 instanceof Workable);  // true

        Employee en = null;
        System.out.println(en instanceof Employee);  // false
    }
}
```

## 3. 编译期限制

`instanceof` 不是随便写的，编译器会先检查==左右两边的静态类型有没有可能兼容==。如果永远不可能成立，直接编译报错：`inconvertible types`。

### 3.1 允许的情况

```java
Object o = ...;
Employee e = ...;

o instanceof Manager;        // 允许：Object 可能指向任何对象
e instanceof Manager;        // 允许：父类引用可能指向子类对象
e instanceof Employee;       // 允许：类型相同
e instanceof Workable;       // 允许：Employee 的非 final 子类可能实现该接口
```

### 3.2 编译报错的情况

```java
Employee e = ...;
String s = ...;

e instanceof String;         // 编译错误：Employee 与 String 无关，且 String 是 final
s instanceof Integer;        // 编译错误：两个 final 类，不可能有交集
int x = 1;
x instanceof Integer;        // 编译错误：基本类型不能用于 instanceof
```

报错的原因是：`String` 是 `final` 类，不可能有子类同时又是 `Employee`，所以这个判断永远为 `false`，编译器直接拒绝这种无意义的写法。

### 3.3 泛型不能检查

由于==类型擦除==，运行时不存在 `List<String>` 和 `List<Integer>` 的区别：

```java
Object o = ...;

o instanceof List<String>;   // 编译错误：泛型参数不可具体化
o instanceof List<?>;        // 允许
o instanceof List;           // 允许（原始类型）
```

如果真的需要区分元素类型，只能逐个检查元素：

```java
if (o instanceof List<?> list) {
    for (Object item : list) {
        if (!(item instanceof String)) {
            return false;
        }
    }
}
```

### 3.4 接口与 final 类

```java
final class Tool {}

Object o = new Tool();
o instanceof Workable;       // 允许：Object 可能指向任何类型

Tool t = new Tool();
t instanceof Workable;       // 编译错误：final 的 Tool 不可能实现 Workable
```

规则可以概括为：

> 编译器判断"是否存在某个实际类型，同时是左右两边的子类型"。存在就放行，不存在就报错。

## 4. instanceof 与 getClass()

两者都能判断类型，但语义完全不同：

| 对比项 | `x instanceof T` | `x.getClass() == T.class` |
| --- | --- | --- |
| 子类对象 | ==`true`== | `false` |
| 实现类对象（T 为接口） | ==`true`== | `false`（`getClass()` 返回的是类，不是接口） |
| 精确类型 | 否 | ==是== |
| `x` 为 `null` | ==`false`== | ==抛 `NullPointerException`== |
| 动态代理对象 | 对接口为 `true` | `false` |
| 典型用途 | 向下转型前的检查 | 要求严格同一类型的场景 |

```java
Employee e = new Manager("张三");

System.out.println(e instanceof Employee);          // true
System.out.println(e.getClass() == Employee.class); // false
System.out.println(e.getClass() == Manager.class);  // true
```

### 4.1 在 equals() 中的选择

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Employee e)) return false;
    return Objects.equals(name, e.name);
}
```

用 `instanceof` 的好处是==子类对象也能比较==，但如果子类增加了参与相等判断的字段，就可能破坏==对称性==：

```java
Employee e = new Employee("张三");
Manager m = new Manager("张三");

e.equals(m);   // true（name 相同）
m.equals(e);   // 取决于 Manager.equals 的实现，可能 false
```

如果要求严格"同类型才相等"，可以用 `getClass()`：

```java
if (o == null || getClass() != o.getClass()) return false;
Employee e = (Employee) o;
```

> [!tip] 选择建议
> * 父类是非 `final`、且子类不额外增加相等语义 → 用 `instanceof`；
> * 要求精确类型匹配 → 用 `getClass()`；
> * 无论哪种写法，`equals` 都要保证==自反、对称、传递、一致==，并且 `hashCode` 同步重写。

## 5. 模式匹配（Java 16+）

### 5.1 基本语法

传统写法需要"判断 + 强转"两步：

```java
if (e instanceof Manager) {
    Manager m = (Manager) e;
    m.approve();
}
```

Java 16 起可以合并成==类型模式==：

```java
if (e instanceof Manager m) {
    m.approve();        // m 已经声明并完成转型，无需再强转
}
```

`m` 称为==模式变量==（pattern variable），它的类型就是 `Manager`，作用域由"确定匹配"的位置决定。

### 5.2 作用域：流式作用域（flow scoping）

模式变量只在==编译器能够确定它已经匹配成功==的地方可见：

```java
// 合法：&& 右侧确定 s 已匹配
if (o instanceof String s && s.length() > 0) {
    System.out.println(s);
}

// 合法：提前 return 后，s 在后续代码中确定可用
if (!(o instanceof String s)) {
    return;
}
System.out.println(s);       // 可以直接用

// 编译错误：|| 右侧无法保证 s 已匹配
if (o instanceof String s || s.length() > 0) {   // s.length() 处报错
    ...
}
```

原因：`||` 的右操作数在左操作数为 `false` 时也会执行，此时 `s` 并没有被赋值，所以编译器不允许使用。

### 5.3 不要过度使用模式变量

模式变量适合"就地判断、就地使用"的场景。如果为了少写一行局部变量而把条件写得很绕，可读性反而下降；复杂分支建议拆成独立方法或优先使用多态。

### 5.4 switch 模式匹配（Java 21+）

```java
static String describe(Object o) {
    return switch (o) {
        case Manager m -> "经理: " + m.name;
        case Employee e -> "员工: " + e.name;
        case null -> "空值";
        default -> "其他";
    };
}
```

注意：

* `case` 的顺序有讲究，==子类必须写在父类前面==；
* 如果把 `case Employee e` 写在 `case Manager m` 前面，编译器会报错：`this case label is dominated by a preceding case label`；
* 模式 `switch` 如果没有覆盖 `null`，传入 `null` 会抛 `NullPointerException`（除非写了 `case null`）；
* 需要 JDK 21 及以上（JDK 17～20 为预览特性）。

## 6. 典型用法

### 6.1 安全向下转型

```java
public void giveBonus(Employee e) {
    if (e instanceof Manager m) {
        System.out.println(m.name + " 获得奖金");
        m.approve();
    }
}
```

这是 `instanceof` 最正统的用途：==先确认，再转型==，彻底避免 `ClassCastException`。详见[[向上转型与向下转型]]。

### 6.2 处理异构集合

```java
List<Object> items = List.of(
    new Manager("张三"),
    "一段文本",
    42
);

for (Object item : items) {
    if (item instanceof Manager m) {
        System.out.println("经理: " + m.name);
    } else if (item instanceof String s) {
        System.out.println("字符串: " + s);
    } else if (item instanceof Integer n) {
        System.out.println("整数: " + n);
    }
}
```

### 6.3 重写 equals()

见 4.1 节。`instanceof` 可以同时完成 `null` 检查和类型检查，代码最简洁。

### 6.4 参数校验与框架回调

```java
public void handle(Object event) {
    if (event instanceof MouseEvent me) {
        // 处理鼠标事件
    } else if (event instanceof KeyEvent ke) {
        // 处理键盘事件
    }
}
```

框架、事件总线、序列化库这类"第三方类型无法修改"的场景，`instanceof` 往往是唯一可行的分发方式。

## 7. 反模式：用 instanceof 代替多态

```java
// 坏味道：每新增一种员工，这里的 if 链都要改
for (Employee e : staff) {
    if (e instanceof Manager m) {
        System.out.println("经理奖金: " + m.getBonus());
    } else if (e instanceof HourlyEmployee h) {
        System.out.println("时薪: " + h.getRate());
    } else if (e instanceof Intern i) {
        System.out.println("实习生补贴: " + i.getAllowance());
    }
}
```

这段代码的问题：

* ==违反开闭原则==：新增子类必须修改这里；
* 类型判断分散在业务代码里，子类的知识泄漏到调用方；
* 容易漏分支，且顺序写错会屏蔽子类（父类分支在前）。

更好的写法是把差异行为交给多态：

```java
abstract class Employee {
    public abstract void printSalaryDetail();
}

class Manager extends Employee {
    @Override
    public void printSalaryDetail() {
        System.out.println("经理奖金: " + bonus);
    }
}

for (Employee e : staff) {
    e.printSalaryDetail();     // 调用方完全不需要知道具体类型
}
```

> [!note] 什么时候 instanceof 是合理的
> * 类型来自外部、无法修改（JDK、第三方库）；
> * 实现 `equals()`；
> * 做一次性分支判断，且分支不会持续增长；
> * 向下转型前的安全检查。
>
> 如果你的 `instanceof` 链随着业务不断变长，就该考虑[[面向抽象编程]]了。

## 8. 常见误区

### 8.1 以为 null instanceof 会抛异常

```java
Object o = null;
System.out.println(o instanceof Object);   // false
```

`instanceof` 对 `null` 永远返回 `false`，这是它比 `getClass()` 安全的地方。

### 8.2 把编译时类型当成判断依据

```java
Employee e = new Manager("张三");
System.out.println(e instanceof Manager);   // true
```

`e` 声明为 `Employee`，但实际对象是 `Manager`，`instanceof` 看的是后者。

### 8.3 兄弟类判断永远为 false

```java
Employee e = new Manager("张三");
System.out.println(e instanceof HourlyEmployee);   // false
```

`Manager` 和 `HourlyEmployee` 是兄弟类，一个对象不可能同时是两者。

### 8.4 用 instanceof 检查泛型实参

```java
o instanceof List<String>;   // 编译错误
```

类型擦除后运行时只有 `List`，没有 `List<String>`。

### 8.5 对基本类型使用 instanceof

```java
int x = 1;
x instanceof Integer;        // 编译错误
```

`instanceof` 只接受引用类型。包装类判断要这样写：

```java
Integer x = 1;
x instanceof Integer;        // true
```

### 8.6 instanceof 为 true 后仍然强转

```java
if (e instanceof Manager) {
    Manager m = (Manager) e;   // 冗余
}
```

Java 16+ 直接写 `if (e instanceof Manager m)` 即可。

### 8.7 和 getClass() 混用

`instanceof` 接受子类，`getClass()` 要求精确类型。在 `equals()`、缓存键、类型注册表等场景，两者语义不同，不能随手替换。

### 8.8 忘记数组也是对象

```java
Object arr = new int[3];                        // 用 Object 接收，才有运行期判断的余地
System.out.println(arr instanceof int[]);       // true
System.out.println(arr instanceof Object);      // true
System.out.println(arr instanceof Object[]);    // false，int[] 不是 Object[]
```

注意，如果变量静态类型就是 `int[]`，写 `arr instanceof Object[]` 会直接编译报错（`int[]` 无法转换为 `Object[]`）。数组的运行时类型是"元素类型 + 维度"，判断时同样遵循实际类型规则。

## 9. 版本说明

| 特性 | 引入版本 | 说明 |
| --- | --- | --- |
| 基本 `instanceof` | Java 1.0 | 一直可用 |
| `instanceof` 类型模式 | Java 16 正式（JEP 394） | Java 14/15 为预览 |
| `switch` 模式匹配 | Java 21 正式（JEP 441） | Java 17～20 为预览 |
| 记录模式（record pattern） | Java 21 正式（JEP 440） | 用于解构 record |

如果项目还在 Java 8/11，只能使用传统的"`instanceof` + 强转"写法，`switch` 模式也不可用。

## 10. 小结

* `instanceof` 在==运行期==判断对象的实际类型，返回 `boolean`；
* 实际类型是目标类型本身、子类或实现类时返回 `true`；`null` 永远返回 `false`；
* 编译期会拒绝"永远不可能成立"的判断（无关的 `final` 类、基本类型、泛型实参）；
* `instanceof` 接受子类，`getClass()` 要求精确类型，`null` 上前者安全、后者抛 NPE；
* Java 16+ 用类型模式 `o instanceof T t` 代替"判断 + 强转"；Java 21+ 可在 `switch` 中使用模式；
* `instanceof` 适合做向下转型前的保护和外部类型分发，==不要用它替代多态==。

## 关联笔记

* [[向上转型与向下转型]] —— 向下转型的风险与安全写法
* [[动态绑定]] —— 运行期如何按实际类型选择方法
* [[继承]] —— 父子类关系是 instanceof 判断的基础
* [[抽象类]] / [[接口]] —— 面向抽象编程，减少类型判断
* [[面向抽象编程]] / [[开闭原则]] —— 为什么不要滥用 instanceof
