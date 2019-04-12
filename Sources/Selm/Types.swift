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
public typealias DependsOn<Item: Equatable> = (Item, (Item) -> ()) -> ()
public typealias DependsOn2<Item1: Equatable, Item2: Equatable> = (Item1, Item2, (Item1, Item2) -> ()) -> ()
