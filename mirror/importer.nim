import httpclient2, json, strutils
var client = newHttpClient()
client.headers = newHttpHeaders({"Accept": "*/*"})
client.headers["User-Agent"] = "curl/7.58.0"
client.headers["X-FIGMA-TOKEN"] = readFile(".figmakey")

let url = "https://www.figma.com/file/TQOSRucXGFQpuOpyTkDYj1/Fidget-Mirror-Test?node-id=0%3A1&viewport=952%2C680%2C1"

let fileKey = url.split("/")[4]
echo fileKey
writeFile("import.json", pretty parseJson(client.getContent("https://api.figma.com/v1/files/" & fileKey)))
