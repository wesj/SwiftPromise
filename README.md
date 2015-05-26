# SwiftPromise
Another swift promises implementation.

I realize that Reactive stuff is all the rage right now, but I've always been curious if its possible to write a Task.jsm (http://taskjs.org/) equivalent in Swift. Halfway through that project, I sorta realized that Futures do mostly the same thing. And there's got to be a nice Futures implementation for ObjC/Swift somewhere out there, right?... I still haven't seen that, but I assume it exists. Seemed a shame to waste this though.

The Promises implementation in here is pretty typical:
```
var p = Promise()
p.then({ value -> AnyObject? in
  // value is 1
  let p2 = Promise()
  p2.resolve(2)
  return p2
}).then({ value -> AnyObject? in
  // value is 2
  return value
}).catch({ (err) -> AnyObject? in
  return err
})
p.resolve(1)
```
It handles:
* Nested promises as well
* Fullfilled on resolved callbacks on individual methods
* TODO: Make sure returning a promise from a catch or fulfilled block works.
* TODO: Use more generics throughout. I hate you Swift compiler, but I'm also still debating how to handle things like: ```Promise.all([1, "Foo", Cat()])```

Probably slightly more interesting is the Yielder class. They allow you to create a function that pauses execution mid thread:
```
let doAsync = Yielder({ yield -> Int? in
  for i in 0..<2 {
    yield(res: i)
  }
  return nil
})

doAsync() // Returns 0 its first call
doAsync() // Returns 1 on its second call
doAsync() // Returns nil. doAsync is now finished
doAsync() // Starts the function over. Returns 0 again.
```
