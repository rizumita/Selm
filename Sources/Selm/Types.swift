//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation

public typealias SelmUpdate<Msg, Model> = (Msg, Model) -> (Model, Cmd<Msg>)
public typealias SelmUpdateExt<Msg, ExternalMsg, Model> = (Msg, Model) -> (Model, Cmd<Msg>, ExternalMsg)
public typealias SelmRoute<Msg, Model> = (Model, @escaping Dispatch<Msg>) -> ()
public typealias SelmView<Msg, Model> = (Model, @escaping Dispatch<Msg>) -> ()
public typealias Dispatch<Msg> = (Msg) -> ()
public typealias Sub<Msg> = (@escaping Dispatch<Msg>) -> ()
public typealias DependsOnOptional<Item: Equatable> = (Item?, (Item) -> ()) -> ()
public typealias DependsOn<Item: Equatable> = (Item, (Item) -> ()) -> ()
public typealias DependsOnOptionalReturn<Item: Equatable, R> = (Item?, (Item) -> R) -> R
public typealias DependsOnReturn<Item: Equatable, R> = (Item, (Item) -> R) -> R
public typealias ChangesOn<Item: Equatable> = (Item?, (Item?) -> ()) -> ()
