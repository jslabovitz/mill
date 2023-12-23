# TODO

- rename Archive/@archive -> Resources/@resources

- split out commands to separate files
  - use Simple::Command

- move logic of trivial commands from Site into command class

- use RunCommand instead of `system`

- use Simple::Config instead of lots of ivars in Site

- remove Textile usage
  - implement only in sites that need it (eg, MTS)

- build site to memory without cleaning/saving

- add 'serve' command to serve from memory with WEBrick, etc.
  - don't require building
  - use rerun to reload when files changed?

- move Site#print_tree, #document_tree, etc. to Archive/Resource

- rename Archive -> Resources

- rework 'advertised/hidden' attribute
  - 'hidden' is mostly used for /error.html
  - 'draft' docs are removed -- should they be?
  - do implicitly by finding all documents connected to root
  - rename?

- add footer to markup format?
  - like header, but at bottom
  - separated by '---' or other separator
  - can be used for navigation, footnotes, or other links