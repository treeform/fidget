# ## Fidget importer.
# ##
# import httpclient, asyncdispatch
# import print

# var figmaKey = readFile(".figmakey")
# var pageId = readFile(".fidget")

# print figmaKey, pageId

# #client.headers["User-Agent"] = "curl/7.55.1"
# #client.headers["Content-Type"] = "application/json"
# #client.headers["X-FIGMA-TOKEN"] = "138594-4937286f-1a1d-4c58-8656-213b22caf788"
# echo client.headers

# var client = newAsyncHttpClient()
# echo client.getContent("https://api.figma.com/v1/files/lm9EyvvPSanY7qZeuAyfES")



import httpclient2, asyncdispatch, json
var client = newHttpClient()
client.headers = newHttpHeaders({"Accept": "*/*"})
client.headers["User-Agent"] = "curl/7.58.0"
client.headers["X-FIGMA-TOKEN"] = "138594-4937286f-1a1d-4c58-8656-213b22caf788"
writeFile("import.json", pretty parseJson(client.getContent("https://api.figma.com/v1/files/lm9EyvvPSanY7qZeuAyfES")))