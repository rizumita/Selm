# Selm

Selm is the framework to realize Elm architecture in Swift.
Elm architecture have had influence on Redux.

Selm has the following features.

- Dispatch is type safety.
- Because the relationship between model and sub-model (view and sub-view) is described by the model and message, the writing that process is easy. 

SelmはSwiftでElmアーキテクチャを実現するためのフレームワークです。
ElmアーキテクチャはReduxに影響を与えたアーキテクチャです。

- Dispatchが型安全である
- モデル間（ビュー間）の関係がモデルとメッセージで記述されるので、モデル間（ビュー間）での処理が記述しやすい

といった特徴があります。

## How to use

If you want to know how to use Selm framework, please read [documents](/Docs).

Selmフレームワークの利用方法を知りたいのであれば、[documents](/Docs)を参照してください。

## Sample

A sample of a app using Selm is included this repository.
If you want to know actual code, please look the sample.

Selmを利用したアプリのサンプルはこのリポジトリに含まれています。
実際のコードを知りたいのであればサンプルを参照してください。

## How to use

### Swift Package Manager

Run 'Add Package Dependency...' from Xcode file menu.
Input this repository URL.

XcodeのファイルメニューからAdd Package Dependency...を実行します。
このリポジトリのURLを入力します。

### Carthage

Add following to your Cartfile

```
github "rizumita/Selm"
```

and follow the Carthage usage.
