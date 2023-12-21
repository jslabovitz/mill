# TODO

- splilt out commands to separate files
  - use Simple::Command

- move logic of trivial commands from Site into command class

- use RunCommand instead of `system`

- use Simple::Config instead of lots of ivars in Site

- build site to memory without cleaning/saving

- add 'serve' command to serve from memory with WEBrick, etc.
  - don't require building
  - use rerun to reload when files changed?

- add footer to markup format?
  - like header, but at bottom
  - separated by '---' or other separator
  - can be used for navigation, footnotes, or other links