# `ppx_map`

`ppx_map` is a PPX rewriter to simplify the definition of maps.

## Usage

### Simple cases

If the type of your map keys is simple enough (`bool`, `char`, `float`, `int`, `string` or `unit`) and the PPX can deduce it, it is as simple as:

```ocaml
[%map 0 => "zero"; 1 => "one"; 2 => "two"]
```

which will give something similar to:

```ocaml
let module Int_map = Map.Make (Int) in
Int_map.(empty |> add 0 "zero" |> add 1 "one" |> add 2 "two")
```

The extension is able to automatically type the map if the first key is a non-bound value (*e.g. not defined by a `let`*) of the types given above. For example,

```ocaml
let a = 0 in
[%map a => "zero"; 1 => "one"; 2 => "two"]
```

will give the following compilation error:

```
Error: `map' cannot infer the type of this value. You need to give an explicit
       bool, char, float, int, string or unit.
```

whereas

```ocaml
let a = 0 in
[%map 1 => "one"; a => "zero"; 2 => "two"]
```

will work just fine.


### More complex cases

#### Simple modules

If the first key you give is a bound value, you need to help the rewriter a little:

```ocaml
let (a, b, c) = (0, 1, 2) in
[%map.Int a => "zero"; b => "one"; c => "two"]
```

or

```ocaml
let (a, b, c) = (0, 1, 2) in
[%map Int; a => "zero"; b => "one"; c => "two"]
```

For simple modules, the first syntax should be preferred (one character shorter ).


#### Functors

You can also use functors! But only the second syntax is going to work:

```ocaml
[%map Functor (Module); key => value]
```

These functors need to be of arity 1 (`Functor (Module) (Module')` cannot be used as it wouldn’t work well with OCaml’s parser). As we could expect, using a generative functor gives the following compilation error:

```
Error: This expression has type 'a $Map.t
       but an expression was expected of type 'b
       The type constructor $Map.t would escape its scope
```

Don’t do that!