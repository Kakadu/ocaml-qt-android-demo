external print_hack: string -> unit = "caml_print_hack"

let doCaml () = "Hello from OCaml"

let () =
  Callback.register "doCaml" doCaml;
  ()
