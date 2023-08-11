{.define: ssl}
import strutils, httpClient, os, xmlparser, xmltree, streams


proc main() =
    if not os.fileExists("Vulkan-Docs/xml/vk.xml"):
        let client = newHttpClient()
        let glUrl = "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/main/xml/vk.xml"
        client.downloadFile(glUrl, "Vulkan-Docs/xml/vk.xml")

    let file = newFileStream("Vulkan-Docs/xml/vk.xml", fmRead)
    let xml = file.parseXml()

if isMainModule:
    main()