# TODO

- use HashStruct for markup header?
  - then remove writers from relevant resources

- split out commands to separate files
  - use Simple::Command

- move logic of trivial commands from Site into command class

- use RunCommand instead of `system`

- use Simple::Config instead of lots of ivars in Site

- make Resources use tree for lookup instead of dictionary
  - keep simple array of resources for quick access/iterators