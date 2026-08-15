--[[
    LanguageManager.luau by fridge
    An incredibly easy way to localize your scripts!

    License: GNU Lesser General Public Version 2.1
    Copyright (c) 2026 fridge
    All rights reserved.
--]]

-- // Services \\ --
local HttpService: HttpService = cloneref(game:GetService("HttpService"));

-- // Library \\ --
local LanguageManager = {
    LanguageRepositoryURL = "", -- The URL where language files are downloaded from. Usually a GitHub repository or something.
    LanguageFolder = "MyScript/Languages/", -- The place where your language files are kept. This isn't created for you, you have to do it yourself!
    SanitizeFilesystemStrings = true, -- Heavily recommended to keep this on!

    -- Language stuff
    CurrentLanguage = {
        Name = "", -- This can be anything from "en-us" to "English" to "Kingdom of Cats"
        Decoded = {} -- Luau table version of the current language.
    },
    CurrentFallbackLanguage = {
        Name = "", -- This can be anything from "en-us" to "English" to "Kingdom of Cats"
        Decoded = {} -- Luau table version of the current fallback language.
    },
};

-- Helper functions to make error handling easier
local function ReadFileFromLanguageFolder(FileName: string): string
    local ReadSuccess, Content = pcall(readfile, string.format("%s%s.json", 
        LanguageManager:SanitizeStringForFolderPath(LanguageManager.LanguageFolder),
        LanguageManager:SanitizeStringForFileName(FileName)));
    if (ReadSuccess) then return Content; else return ""; end;
end;

local function WriteFileToLanguageFolder(FileName: string, Content: string): boolean
    local WriteSuccess = pcall(writefile, string.format("%s%s.json",
        LanguageManager:SanitizeStringForFolderPath(LanguageManager.LanguageFolder),
        LanguageManager:SanitizeStringForFileName(FileName)), Content);
    if (WriteSuccess) then return true; else return false; end;
end;

local function DecodeLanguage(Language: string): {}
    local DecodeSuccess, Result = pcall(function() return HttpService:JSONDecode(Language); end);
    if (DecodeSuccess) then return Result; else return {}; end;
end;

local function IsLanguageDownloaded(Language: string): boolean
    local CheckSuccess = pcall(isfile, string.format("%s%s.json",
        LanguageManager:SanitizeStringForFolderPath(LanguageManager.LanguageFolder),
        LanguageManager:SanitizeStringForFileName(FileName)));
    if (CheckSuccess) then return true; else return false; end;
end;

--[[
    This function will update the current language
    in use by LanguageManager, and also decode it
    automatically. It must be the name of a language
    file that is already on the device.
--]]
local function UpdateCurrentLanguage(Language: string, IsFallback: boolean): boolean
    -- Check if the language exists first
    if (not IsLanguageDownloaded(
        LanguageManager:SanitizeStringForFileName(Language))) then return false; end;

    if (not IsFallback) then
        LanguageManager.CurrentLanguage.Name = Language;
        LanguageManager.CurrentLanguage.Decoded = DecodeLanguage(
            ReadFileFromLanguageFolder(LanguageManager:SanitizeStringForFileName(Language)));

        return true;
    else
        LanguageManager.CurrentFallbackLanguage.Name = Language;
        LanguageManager.CurrentFallbackLanguage.Decoded = DecodeLanguage(
            ReadFileFromLanguageFolder(LanguageManager:SanitizeStringForFileName(Language)));

        return true;
    end;
end;

--[[
    Returns a sanitized version of a string that is
    able to be used with file functions.
--]]
function LanguageManager:SanitizeStringForFileName(Name: string): string?
    -- Removes any whitespace in the name as well as
    -- bad characters that don't work in file names.
    if (LanguageManager.SanitizeFilesystemStrings) then
        return (Name:gsub("[<>:\"/\\|%?%*%z%c]", ""):match("^%s*(.-)%s*$"));
    else
        return Name;
    end;
end;

--[[
    Returns a sanitized version of a string that is
    able to be used with folder functions.
--]]
function LanguageManager:SanitizeStringForFolderPath(Path: string): string?
    if (LanguageManager.SanitizeFilesystemStrings) then
        -- Turn back slashes into forward slashes
        Path = Path:gsub("\\", "/");

        -- Split into segments
        local Segments = {};
        for Segment in Path:gmatch("[^/]+") do
            table.insert(Segments, Segment);
        end;

        -- Sanitize each segment of the path
        local CleanSegments = {};
        for _, Segment in ipairs(Segments) do
            local CleanSegment = LanguageManager:SanitizeStringForFileName(Segment);

            if (CleanSegment ~= "" and CleanSegment ~= "." and CleanSegment ~= "..") then
                table.insert(CleanSegments, CleanSegment);
            end;
        end;

        if (#CleanSegments == 0) then return ""; end;
        return table.concat(CleanSegments, "/") .. "/";
    else
        return Path;
    end;
end;

--[[
    The URL which LanguageManager will attempt to
    download new language files from. Existing ones
    will not be deleted or replaced.

    The repository should be valid JSON files with
    any NTFS-accepted name.
--]]
function LanguageManager:SetLanguageRepositoryURL(URL: string)
    LanguageManager.LanguageRepositoryURL = URL;
end;

--[[
    Returns the URL LanguageManager will download
    language files from.
--]]
function LanguageManager:GetLanguageRepositoryURL(): string
    return LanguageManager.LanguageRepositoryURL;
end;

--[[
    Sets the folder (relative to the workspace) that
    LanguageManager will write and read language
    files from. Sanitized before being set.

    The folder is not recursively created, and it
    must be created beforehand.
--]]
function LanguageManager:SetLanguageFolder(Folder: string)
    LanguageManager.LanguageFolder = LanguageManager:SanitizeStringForFolderPath(Folder);
end;

--[[
    Returns the folder path as a string that 
    LanguageManager uses to store language files in. 
--]]
function LanguageManager:GetLanguageFolder(): string
    return LanguageManager.LanguageFolder;
end;

--[[
    Sets the current language that will be used for
    translations. It must be the name of a language
    file that is already on the device.
--]]
function LanguageManager:SetCurrentLanguage(Language: string): boolean
    return UpdateCurrentLanguage(
        LanguageManager:SanitizeStringForFileName(Language), false);
end;

--[[
    Returns the current language that is in use by
    LanguageManager.
--]]
function LanguageManager:GetCurrentLanguage(): {Name: string, Decoded: {}}
    return LanguageManager.CurrentLanguage;
end;

--[[
    Attempts to download the specified language JSON
    file from the language repository.

    Most services follow the country-code format for language
    files. An example would be "en-us" for United States English 
    or "nl-nl" for Netherlands Dutch.

    Returns true if the download succeeded and the file is
    properly JSON-encoded. Returns false if otherwise.
--]]
function LanguageManager:DownloadLanguage(Language: string, Overwrite: boolean): boolean
    -- Pre-download checks
    if (IsLanguageDownloaded(LanguageManager:SanitizeStringForFileName(Language)) and not Overwrite) then return false; end;
    if (LanguageManager:GetLanguageRepositoryURL() == "") then return false; end;

    local DownloadedLanguageFile = game:HttpGet(string.format("%s%s.json",
        LanguageManager:GetLanguageRepositoryURL(), 
        HttpService:UrlEncode(LanguageManager:SanitizeStringForFileName(Language))));
    if (DownloadedLanguageFile) then
        -- Attempt to decode language file for verification
        if (DecodeLanguage(DownloadedLanguageFile) ~= {}) then
            return WriteFileToLanguageFolder(
                LanguageManager:SanitizeStringForFileName(Language), DownloadedLanguageFile);
        else
            return false;
        end;
    else
        return false;
    end;
end;

--[[
    Attempts to download all of the languages that
    were passed in at once.
--]]
function LanguageManager:DownloadLanguages(Languages: {string}, OverwriteAll: boolean)
    for Index, Language in pairs(Languages) do
        LanguageManager:DownloadLanguage(
            LanguageManager:SanitizeStringForFileName(Language), OverwriteAll);
    end;
end;

--[[
    Checks if the specified language has a
    corresponding file on the device.
--]]
function LanguageManager:IsLanguageDownloaded(Language: string): boolean
    return IsLanguageDownloaded(LanguageManager:SanitizeStringForFileName(Language));
end;

--[[
    Sets the current language that will be used for
    fallback translations. It must be the name of a
    language file that is already on the device.
--]]
function LanguageManager:SetCurrentFallbackLanguage(Language: string): boolean
    return UpdateCurrentLanguage(LanguageManager:SanitizeStringForFileName(Language), true);
end;

--[[
    Returns the current fallback language that is in
    use by LanguageManager.
--]]
function LanguageManager:GetCurrentFallbackLanguage(): {Name: string, Decoded: {}}
    return LanguageManager.CurrentFallbackLanguage;
end;

--[[
    Gets the string with the specified key in the
    loaded language. Falls back to the specified
    fallback language if there isn't a translation
    in the main language, and then falls back to the
    key if there isn't a translation in the fallback
    language.
--]]
function LanguageManager:GetKey(Key: string): string
    -- Check if there's a language loaded
    if (LanguageManager.CurrentLanguage.Name == "") then return ""; end;

    -- Check if we need to fallback first
    if (LanguageManager.CurrentLanguage.Decoded[Key] == nil) then
        if (LanguageManager.CurrentFallbackLanguage.Decoded[Key] == nil) then
            return Key;
        else
            return LanguageManager.CurrentFallbackLanguage.Decoded[Key];
        end;
    end;

    return LanguageManager.CurrentLanguage.Decoded[Key];
end;

--[[
    Gets the string with the specified key in the
    loaded language, and then formats the remaining
    arguments into it. Falls back to the specified
    fallback language if there isn't a translation
    in the main language, and then falls back to the
    key if there isn't a translation in the fallback
    language. The fallback key string will also be
    formatted.
--]]
function LanguageManager:GetKeyFormatted(Key: string, ...: any): string
    -- Check if there's a language loaded
    if (LanguageManager.CurrentLanguage.Name == "") then return ""; end;

    -- Check if we need to fallback first
    if (LanguageManager.CurrentLanguage.Decoded[Key] == nil) then
        if (LanguageManager.CurrentFallbackLanguage[Key] == nil) then
            return Key;
        else
            return string.format(LanguageManager.CurrentFallbackLanguage[Key], ...);
        end;
    end;

    return string.format(LanguageManager.CurrentLanguage[Key], ...);
end;

--[[
    Returns the existence of the provided key
    in the current loaded language.
--]]
function LanguageManager:DoesKeyExist(Key: string): boolean
    if (LanguageManager.CurrentLanguage.Name == "") then return false; end;
    return LanguageManager.CurrentLanguage.Decoded[Key] ~= nil;
end;

--[[
    Returns the existence of the provided key
    in the current loaded fallback language.
--]]
function LanguageManager:DoesFallbackKeyExist(Key: string): boolean
    if (LanguageManager.CurrentFallbackLanguage.Name == "") then return false; end;
    return LanguageManager.CurrentFallbackLanguage.Decoded[Key] ~= nil;
end;

return LanguageManager;
