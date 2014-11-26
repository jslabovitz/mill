# Principles of resources

- A single input file can generate one or more resources.

- A resource can refer to zero or more input files.

- A resource can render to zero or more output files.

- A resource is referenced by a _path._ The path looks like an absolute POSIX path, or the path component of a URI. Some resources have an extension as part of their path, but it is not required.


## _Generic_ and _custom_ resources

A resource contains, at minimum, a path.


## _File_ resources

```xml
  <file path="/foo.css" 
        source="content/foo.css" 
        type="text/css"/>
```


## _Image_ resources

```xml
  <file path="/foo.jpg" 
        source="tmp/images/foo.jpg" 
        type="image/jpeg" 
        width="200" 
        height="400"/>
```


## _Page_ resources

```xml
  <page path="/foo.html" 
        type="text/html">
    <html>
      <h1>A heading</h1>
      <p>Describing something.</p>
    </html>
  </page>
```


## _Collection_ resources

A collection resource is used to refer to one or more related resources. For example, an image may have multiple sizes or formats, each of which are represented by their own resource.

A collection resource collects its members and offers a top-level way to access them (via the collection's path), metadata that is shared amongst all members of the collection (such as a caption), as well as an organizational system of referring to individual members without needing to know their specific paths.

```xml
  <collection path="/foo" default="medium">
    <description>A picture of a foo.</description>
    <image path="/foo.jpg"   tag="medium"    />
    <image path="/foo_t.jpg" tag="thumbnail" />
    <image path="/foo.tiff"  tag="original"  />
  </collection>
```

Each member of a collection has a required `xpath` attribute that specifies the path of the resource being referred to.

Each member may have a `tag` attribute, which must be unique within that collection. The `collection` element has an optional `default` attribute, which refers to one of the members' tags. A member of a collection may be specified by extending its path to include the tag. For example, the path `foo/medium` is equivalent to `foo/foo.jpg`.

---

  resources should have to_html methods
    replaces add_image_sizes
    replaces Polymecca#decorate_inline_images

