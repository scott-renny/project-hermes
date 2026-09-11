function Initialize()
    filePath = SKIN:MakePathAbsolute(SELF:GetOption("FilePath"))
    content = ""
end

function Update()
    local file = io.open(filePath, "r")
    if file then
        content = file:read("*all") or ""
        file:close()
        content = content:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\n+$", "")
    end
    return content
end
