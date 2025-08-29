```bash
tools/generator.nim
4:import nstd
29:  let args = nstd.getArgs()

tools/helpers.nim
7:import nstd/format as nstdFormat ; export nstdFormat

VulkanNim.nimble
68:taskRequires "genvk", "https://github.com/heysokam/nstd#head" # For parseopts extensions
74:taskRequires "genvideo", "https://github.com/heysokam/nstd#head" # For parseopts extensions

examples/cstringArray.nim
2:# Also available from nstd
4:# https://github.com/heysokam/nstd/blob/master/src/nstd/strings.nim#L100
```
