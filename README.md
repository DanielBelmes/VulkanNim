# VulkanNim
Vulkan bindings for Nim, influenced by VulkanHpp

## Usage
```nim
# Somewhere in your project's .nimble file
requires "https://github.com/DanielBelmes/VulkanNim#head"
```
```nim
import VulkanNim
# ... Use Vulkan
```

## Header Generator
> @note:  
> The bindings are already generated and included in this library.  
> Using the Header Generator is not needed at all, unless you are trying to update the bindings to the latest version of the spec.
>
> If you run into a symbol that is not included in the bindings, but exists in the latest version of the spec,
> please open an issue and we will run the generator to update the bindings.  

### Dependencies
You might need to install pcre for the generator to work.  
`sudo apt install libpcre3`, `yum install pcre`, etc.  

The generator code is not installed when using this library as a nimble dependency.  
You need to clone the [VulkanNim](https://github.com/DanielBelmes/VulkanNim) repository in order to run it.  

### Usage
The code for the generator is located in the [`tools`](./tools) folder.  
Call `nimble genvk` to run it.  
This will output the bindings to the [`src`](./src/VulkanNim) folder.  

