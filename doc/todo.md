> @important  
> Temporary until versioning is resolved.  
> [roadmap.md](./roadmap.md) should be preferred over this file  

## Package Management
- [ ] Update the roadmap to reflect the latest changes
- [ ] Mark the library with a tagged version
  - [ ] Add the version number
        _(likely 0.9.0, or close to it, but need to review every step on the [roadmap](./roadmap.md) before deciding)_
  - [ ] Create a tag : https://github.com/beef331/graffiti


## Base Bindings
### Goals
_Mark done when agreed_
- [ ] Make vulkan usable from Nim
- [ ] Keep the api as C-like as possible
- [ ] Does this version have any other goals ?

### List
- [ ] Update to Vulkan 1.4
      _Currently at: 1.3.281_
- [ ] Functions/Enums are renamed, but not structs
      _Do we want everything renamed, or nothing renamed ?_
- [ ] Decide on a rename style for the base bindings


## Nim-mified bindings
### Goals
_Mark done when agreed_
- [ ] Reduce boilerplate
- [ ] Use Nim types for everything
- [ ] Simplify the API
      _If yes, how_

### List
- [ ] Remove the need for using C types
  - [ ] `cstring` to `string`
        Decide which option we prefer
        Options: converter, wrapper functions, templates
- [ ] Nim-mified functions
      _Options: vkbootstrap-like approach, sokam's cvk approach, alternative to vkbootstrap (without function chaining)_
- [ ] Sane Default Values for structs, based on the spec
      _Problem to solve: The spec file does not provide a value, but most objects require one and that'd be sane default_

