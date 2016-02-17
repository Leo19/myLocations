//: Playground - noun: a place where people can play
// Leo)Xcode 7.2

import UIKit

var str = "Hello, playground"

class Bank {
    static var coinsInBank = 1_0000
    
    // 分发硬币，并返回结果
    static func vendCoins(var numberOfCoins numberOfCoinsToVend: Int) -> Int {
        numberOfCoinsToVend = min(numberOfCoinsToVend,coinsInBank)
        coinsInBank -= numberOfCoinsToVend
        return numberOfCoinsToVend
    }
    
    // 收取硬币，简单的加法
    static func receiveCoins(let intCoins coins: Int) {
        coinsInBank += coins
    }
}


class Player {
    var coinsInPurse: Int
    
    // 初始化给一个金币数量
    init(coins: Int){
        coinsInPurse = Bank.vendCoins(numberOfCoins: coins)
    }
    
    // 获取金币存入钱包，coinsInBank要做减法
    func winCoins(coins: Int) {
        coinsInPurse += Bank.vendCoins(numberOfCoins: coins)
    }
    
    // 析构实例的时候释放金币到Bank
    deinit {
        Bank.receiveCoins(intCoins: coinsInPurse)
    }
}

var playerOne: Player? = Player(coins: 100)
print("System: A new bee has joined the game with \(playerOne!.coinsInPurse) coins")
print("System: There are now \(Bank.coinsInBank) coins left")


playerOne = nil
print("System: PlayerOne has left left the game")
print("System: The bank now has \(Bank.coinsInBank) coins")



/* ===================== 关于Strong Reference ===================== */
/* 对象都是引用类型的所以才会造成强引用，两个对象之间互相的强引用会造成循环引用 */
/* 还有一个是闭包它也是引用类型，闭包作为对象的一个属性，然后闭包还可以在闭包体 */
/* 里捕获self，造成循环引用。避免循环引用的方法总共有两种，用weak和unowned关 */
/* 键字变量有为nil的需要则用weak，如果该属性不允许为nil则应该用unowned关键字 */
class Person {
    let name: String
    init(name: String) {
        self.name = name
        print("\(name) is being initialized")
    }
    
    deinit {
        print("\(name) is being deinitialized")
    }
}

var reference1: Person?
var reference2: Person?
var reference3: Person?

reference1 = Person(name: "Leoooo")
reference1 = nil

/*  ========== 人对应公寓，但公寓并不一定有人，人也未必有公寓所有都是Optional ========= */
class People {
    let name: String
    var apartment: Apartment?
    init(name: String){
        self.name = name
    }
    deinit{
        print("People deinit: \(name) is being initialized")
    }
}
class Apartment {
    let unit: String
    
    // 不加weak会产生强引用，进而产生循环引用
    // var tenant: People?
    
    // 如果生命周期内可能变为nil推荐使用weak
    weak var tenant: People?
    init(unit: String){
        self.unit = unit
    }
    deinit{
        print("Apartment deinit: \(unit) is being deinitialized")
    }
}
var john: People?
var unit410: Apartment?

// 先创建People 和 Apartment变量
john = People(name: "Leoooooo")
unit410 = Apartment(unit: "6#410")

// 互相赋值之后就变成了循环引用了
john!.apartment = unit410
unit410!.tenant = john

// 循环引用了，所以不会执行析构函数
john = nil
unit410 = nil

/*  ========== 客户可能没有信用卡，但是一张信用卡总会关联一个客户 ========= */
class Customer {
    let name: String
    var card: CreditCard?
    
    init (name: String) {
        self.name = name
    }
    
    deinit {
        print("Customer: \(name) is being deinitialized ")
    }
}

class CreditCard {
    let number: UInt64
    
    // 如果没有unowned的关键字会产生循环引用
    // let customer: Customer
    
    // 信用卡肯定关联着一个客户，所以这里不是Optional的要用unowned
    unowned let customer: Customer
    
    init(number: UInt64, customer: Customer) {
        self.number = number
        self.customer = customer
    }
    
    deinit {
        print("Card: #\(number) is being deinitialized")
    }
}

var jack: Customer?
jack = Customer(name: "Jack Luuu")
jack!.card = CreditCard(number: 6226_5678_0455, customer: jack!)
jack = nil

/* ====================== 总结 ====================== */
/* Person 和 Apartment 的例子展示的是两个属性的值都允许为nil */
/* 此时为了避免循环引用， 这种场景适合通过用弱引用来解决循环引用 */
/* Customer 和 CreditCard 的例子展示了其中一个属性值为nil而 */
/* 另外一个属性的值不允许为nil，在这种场景中，需要用无主属性 */
/* 然而还有第三种场景，强一对一关系，就是对方引用的属性都不为nil */
/* 此时要解决循环引用一方要用unowned，另外一方要用隐式可选属性 */
/* 也就是用!感叹号 */

class Country {
    let name: String
    var capitalCity: City!
    
    // 这个构造方法有说道：swift的两段式构造
    init(name: String, capitalName: String){
        // 只要给存储属性赋值就行，感叹号那个是nil
        self.name = name
        // 只有所有存储属性赋值完后，才能用self，才能调用本类的实例及其方法
        self.capitalCity = City(name: capitalName, country: self)
    }
}

class City {
    let name: String
    
    // 一个用unowned 另外一个用感叹号隐式解析
    unowned let country: Country
    
    init(name: String, country: Country) {
        self.name = name
        self.country = country
    }
}

var country = Country(name: "Canada", capitalName: "Ottawa")
print("\(country.name)'s capital city is called\(country.capitalCity.name)")



// 这种情况会引起循环引用的原因是闭包会捕获变量，比如捕获了self
class HTMLElement {
    let name: String
    let text: String?
    
    // 如果包含text内容则返回包含文本的段落，否则返回标签类似于<p>some text</p>
    // 没有的标签体的内容的话就是比如<br />
    lazy var asHTML: Void -> String = {
        // [unowned self] in
        // 需要特别说明的是由于是lazy属性才可以使用self
        // 因为初始化完成后self确实存在才能访问lazy属性
        if let text = self.text {
            return "<\(self.name)> \(text)</\(self.name)>"
        } else {
            return "<\(self.name) />"
        }
    }
    
    init(name: String,text: String? = nil){
        self.name = name
        self.text = text
    }
    
    deinit {
        print("HTML \(name) is being deinitialized")
    }
}

let heading = HTMLElement(name: "h1")
let defaultText = "some default text"
heading.asHTML = {
    return "<\(heading.name)>\(heading.text ?? defaultText)</\(heading.name)>"
}
// 此处一坑：闭包后面要带括号才表示立即执行，否则指的是这个闭包
print(heading.asHTML())


var paragraph: HTMLElement? = HTMLElement(name: "p",text: "too nasty")
print(paragraph!.asHTML())

// 这时无法调用析构函数，因为闭包体力使用了self.name 和self.text，因此闭包
// 捕获了self，这意味着闭包反过来持有了HTMLElement实例的强引用
paragraph = nil


// 在定义闭包时同时定义捕获列表作为闭包的一部分，通过这种方式可以解决闭包和类实例
// 之间的循环强引用。捕获列表定义了闭包体内捕获一个或者多个引用类型的规则。捕获列表中
// 每一项都由一对元素组成，一个元素是weak或unowned关键字，另一个元素是实例的引用
// 如果闭包有参数列表和返回类型，把捕获列表放在它们前面，如果没有就放in前面
//lazy var someClosure: (Int,String) -> String = {
//    [unowned self,weak delegate = self.delegate!](index: Int, StringToProcess: String) -> String in
//    // 闭包体
//}

//lazy var someClosure: Void -> String = {
//    [unowned self, weak delegate = self.delegate!] in
//    // 闭包体
//}







