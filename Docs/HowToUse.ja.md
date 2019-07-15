# Selmの使い方

Selmを利用して実装すべき部品は

- モデル
- メッセージ
- 初期化関数
- 状態遷移関数

です。

また、Selmが提供する部品は

- Driver
- Dispatch
- Cmd

などがあります。

これらについて、実装方法・利用方法を解説します。

## モデル

モデルは各ビューの状態です。一般的に構造体で定義します。

Modelの例

```swift
struct MyView: View {
    struct Model {
        var count: Int = 0
    }
}
```

MyView内にMyViewの状態であるModelを定義しています。countプロパティで現在のカウント数を保持します。

## メッセージ

メッセージは状態遷移を行うための入力です。

メッセージの例

```swift
struct MyView: View {
    enum Msg {
        case up
        case down
    }
}
```

MyViewの状態遷移の入力であるMsgを定義しています。upとdownが入力になります。

## 初期化関数

状態の初期化を行う関数です。一般的にinitializeと命名するようにしていますが、他の名前でも定義が可能です。

```swift
struct MyView: View {
    static func initialize() -> (Model, Cmd<Msg>) {
        (Model(), Cmd<Msg>.none)
    }
}
```

MyViewの状態をModel()で初期化して返しています。一緒に返しているCmdでは初期化時に実行するメッセージを指定することができます。ここでは何もしない.noneを返しています。

## 状態遷移関数

状態遷移を行う関数です。一般的にupdateと命名します。

```swift
struct MyView: View {
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        var model = model
        
        switch msg {
        case .up:
            model.count += 1
            return (model, .none)

        case .down:
            model.count -= 1
            return (model, .none)
        }
    }
}
```

MyViewの状態を遷移させる関数です。引数として(Msg, Model)を受け取り、(Model, Cmd<Msg>)を返します。引数のMsgに対応する遷移を記述しています。
返値は状態が遷移したモデルと、追加で実行するメッセージのコマンドです。
モデルの更新はSwiftxなどの関数型プログラミング用のライブラリに存在するパイプ演算子と、以下の関数を利用することで

```swift
public func write<Item, Value>(_ keyPath: WritableKeyPath<Item, Value>) -> (@escaping (Value) -> Value) -> (Item) -> Item {
    { update in
        { item in
            var item = item
            item[keyPath: keyPath] = update(item[keyPath: keyPath])
            return item
        }
    }
}

public func set<Item, Value>(_ keyPath: WritableKeyPath<Item, Value>, _ value: Value) -> (Item) -> Item {
    (write(keyPath)) { _ in value }
}
```

以下のように記述することが可能になります。

```swift
    static func update(_ msg: Msg, _ model: Model) -> (Model, Cmd<Msg>) {
        switch msg {
        case .up:
            return (model |> set(\.count, model.count + 1), .none)

        case .down:
            return (model |> set(\.count, model.count - 1), .none)
        }
    }
```

## Driver

これら定義したオブジェクトや関数からDriverを作成します。
DriverはModelと、以降で説明するDispatchを保持し、Viewとバインドする役割を受け持ちます。

ViewにObjectBindingとしてDriverを保有させます。

```swift
struct MyView: View {
    @ObjectBinding var driver: Driver<MyView.Msg, MyView.Model>
}
```

SceneDelegateでdriverを作成してMyViewにインジェクトします。

```swift
            window.rootViewController = UIHostingController(rootView: MyView(driver: Runner.create(initialize: MyView.initialize, update: MyView.update)))
```

Viewでは以下のように利用します。

```swift
struct MyView : View {
    var body: some View {
        Stepper(onIncrement: {
            self.driver.dispatch(.up)
        }, onDecrement: {
            self.driver.dispatch(.down)
        }) {
            Text(String(self.driver.model.count))
        }
    }
}
```

Driverの所有するdispatchでメッセージを入力し、modelから状態を取り出しています。

## Dispatch

Dispatchは

```swift
public typealias Dispatch<Msg> = (Msg) -> ()
```

と定義されているクロージャです。Driverが保持し、メッセージを渡すことで状態遷移を発生させることができます。

## Cmd

コマンドはメッセージを包んで、Selmが内部で処理するための命令です。
コマンドでは

- Cmd.none 無処理
- Cmd.ofMsg メッセージを処理
- Cmd.batch 複数のコマンドをバッチ処理
- Cmd.ofAsyncMsg メッセージを非同期処理

などを指定することができます。
