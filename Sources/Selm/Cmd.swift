//
// Created by 和泉田 領一 on 2019-04-07.
//

import Foundation

public struct Cmd<Msg> {
    let value: [Sub<Msg>]

    public static var none: Cmd<Msg> { return Cmd<Msg>(value: []) }

    public static func ofMsg(_ msg: Msg) -> Cmd<Msg> {
        return Cmd(value: [{ dispatch in dispatch(msg) }])
    }

    public static func ofMsgOptional(_ msg: Msg?) -> Cmd<Msg> {
        return Cmd(value: [{ dispatch in msg.map(dispatch) }])
    }

    public static func map<A>(_ f: @escaping (A) -> Msg) -> (Cmd<A>) -> Cmd<Msg> {
        return { cmd in
            Cmd<Msg>(value: cmd.value.map { sub in
                { dispatch in sub { a in dispatch(f(a)) } }
            })
        }
    }

    public func map<B>(_ f: @escaping (Msg) -> B) -> Cmd<B> {
        return Cmd<B>.map(f)(self)
    }

    public static func batch(_ cmds: [Cmd<Msg>]) -> Cmd<Msg> {
        return Cmd(value: cmds.flatMap { cmd in cmd.value })
    }

    public static func ofSub(_ sub: @escaping Sub<Msg>) -> Cmd<Msg> {
        return Cmd(value: [sub])
    }

    public static func dispatch(_ dispatch: @escaping Dispatch<Msg>) -> (Cmd<Msg>) -> () {
        return { cmd in cmd.value.forEach { (sub: Sub<Msg>) in sub(dispatch) } }
    }

    public func dispatch(_ dispatch: @escaping Dispatch<Msg>) {
        Cmd.dispatch(dispatch)(self)
    }

    public static func ofAsyncMsg(_ async: @escaping (@escaping (Msg) -> ()) -> ()) -> Cmd<Msg> {
        return Cmd(value: [{ dispatch in
            async { msg in
                DispatchQueue.main.async { dispatch(msg) }
            }
        }])
    }

    public static func ofAsyncMsgOptional(_ async: @escaping (@escaping (Msg?) -> ()) -> ()) -> Cmd<Msg> {
        return Cmd(value: [{ dispatch in
            async { msg in
                guard let msg = msg else { return }
                DispatchQueue.main.async { dispatch(msg) }
            }
        }])
    }

    public static func ofAsyncCmd(_ async: @escaping (@escaping (Cmd<Msg>) -> ()) -> ()) -> Cmd<Msg> {
        return Cmd(value: [{ dispatch in
            async { cmd in
                DispatchQueue.main.async { cmd.dispatch(dispatch) }
            }
        }])
    }

    public static func ofAsyncCmdOptional(_ async: @escaping (@escaping (Cmd<Msg>?) -> ()) -> ()) -> Cmd<Msg> {
        return Cmd(value: [{ dispatch in
            async { cmd in
                guard let cmd = cmd else { return }
                DispatchQueue.main.async { cmd.dispatch(dispatch) }
            }
        }])
    }
    
    public static func ofTask<Value>(mapResult: @escaping (Result<Value, Error>) -> Msg, task: Task<Value>) -> Cmd<Msg> {
        return Cmd(value: [ { dispatch in
            task.work { result in
                let msg = mapResult(result)
                dispatch(msg)
            }
        }])
    }
}
