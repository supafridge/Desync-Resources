--[[
    LanguageManager.luau by fridge
    An incredibly easy way to localize your scripts!

    This library assumes your executor supports filesystem
    functions. If it doesn't, get a better executor.

    License: GNU Lesser General Public Version 2.1
    Repository: https://github.com/supafridge/Desync-Resources

    Copyright (c) 2026 fridge
    All rights reserved.
--]]

-- Services
local HttpService: HttpService = cloneref(game:GetService("HttpService"));

local LanguageManager = {
    RepositoryURL = "",
    WorkspaceFolder = "MyScript/Languages/",
    
    -- The name of the file that corresponds to the language
    CurrentLanguage = "",
    CurrentFallbackLanguage = "",

    -- JSON-decoded versions of the current languages
    CurrentLanguageDecoded = {},
    CurrentFallbackLanguageDecoded = {}
};

-- Helper function to make checking for languages less repetitive
local function IsLanguageDownloaded(Language: string): (boolean, string?)
    local CheckSuccess, Result = pcall(function()
        return isfile(string.format("%s%s.json", LanguageManager.WorkspaceFolder, Language));
    end);

    if (CheckSuccess) then
        return Result;
    else
        return false, "Failed to check if language was downloaded";
    end;
end;

-- Another helper function to make setting languages easier
local function UpdateCurrentLanguage(Language: string, IsFallback: boolean): (boolean, string?)
    -- Check if the language to update to even exists
    if (not IsLanguageDownloaded(Language)) then 
        return false, string.format("Failed to update language: Language %s is not downloaded yet!", Language);
    end;

    if (not IsFallback) then
        local ReadSuccess = pcall(function()
            LanguageManager.CurrentLanguage = Language;
            LanguageManager.CurrentLanguageDecoded = HttpService:JSONDecode(
                readfile(string.format("%s%s.json", LanguageManager.WorkspaceFolder, Language)));
        end);

        if (ReadSuccess) then
            return true;
        else
            return false, "Failed to read language file";
        end;
    else
        local ReadSuccess = pcall(function()
            LanguageManager.CurrentFallbackLanguage = Language;
            LanguageManager.CurrentFallbackLanguageDecoded = HttpService:JSONDecode(
                readfile(string.format("%s%s.json", LanguageManager.WorkspaceFolder, Language)));
        end);

        if (ReadSuccess) then
            return true;
        else
            return false, "Failed to read language file";
        end;
    end;
end;

--[[
    The URL which LanguageManager will fetch language files from.
    These should be JSON files that only have string keys and string values,
    like a dictionary.

    Most commonly a GitHub repository.
--]]
function LanguageManager:SetLanguageRepositoryURL(URL: string)
    LanguageManager.RepositoryURL = URL;
end;

--[[
    Returns the URL that is used as the repository for
    language files.
--]]
function LanguageManager:GetLanguageRepositoryURL(): string
    return LanguageManager.RepositoryURL;
end;

--[[
    Sets the folder relative to the workspace that this
    library will download and fetch on-device languages from.

    This will not (recursively) create the folder until it
    exists. It must be there beforehand.
--]]
function LanguageManager:SetWorkspaceFolder(Path: string)
    LanguageManager.WorkspaceFolder = Path;
end;

--[[
    Returns the folder path as a string that the library
    is working with.
--]]
function LanguageManager:GetWorkspaceFolder(): string
    return LanguageManager.WorkspaceFolder;
end;

--[[
    Downloads a language from the set language repository to the
    set language file location relative to the workspace.

    Most services follow the country-code format for language
    files. An example would be "en-us" for United States English 
    or "nl-nl" for Netherlands Dutch.

    Returns true if the download succeeded and the file is
    properly JSON-encoded. Returns false if otherwise.
--]]
function LanguageManager:DownloadLanguage(Language: string, Overwrite: boolean): (boolean, string?)
    -- Pre-download checks
    if (IsLanguageDownloaded(Language) and not Overwrite) then return true; end;
    if (LanguageManager.RepositoryURL == "") then return false; end;

    local DownloadedLanguageFile = game:HttpGet(string.format("%s%s.json", LanguageManager.RepositoryURL, 
        HttpService:UrlEncode(Language)));
    
    -- Verify the downloaded file is JSON-encoded
    local DecodeSuccess = pcall(function()
        HttpService:JSONDecode(DownloadedLanguageFile);
    end);

    if (DecodeSuccess) then
        local WriteSuccess = pcall(function()
            writefile(string.format("%s%s.json", LanguageManager.WorkspaceFolder,
                Language), DownloadedLanguageFile);
        end);
        
        if (WriteSuccess) then
            return true;
        else
            return false, "Failed to write language file";
        end;
    else
        return false, "Failed to decoded language file";
    end;
end;

--[[
    Will attempt to download all of the languages in the
    passed-in table to the workspace folder.
--]]
function LanguageManager:DownloadLanguages(Languages: {string}, OverwriteAll: boolean)
    for Index, Language in pairs(Languages) do
        LanguageManager:DownloadLanguage(Language, OverwriteAll);
    end;
end;

--[[
    Checks whether or not the specified language file
    is currently on the device.
--]]
function LanguageManager:IsLanguageDownloaded(Language: string): (boolean, string?)
    return IsLanguageDownloaded(Language);
end;

--[[
    Sets the new language to get strings from and
    decodes the new language file.
--]]
function LanguageManager:SetLanguage(Language: string): (boolean, string?)
    return UpdateCurrentLanguage(Language, false);
end;

--[[
    Returns the language that is currently being used.
--]]
function LanguageManager:GetCurrentLanguage(): string
    return LanguageManager.CurrentLanguage;
end;

--[[
    Sets the new language to fallback to in case a
    string doesn't exist.
--]]
function LanguageManager:SetFallbackLanguage(Language: string): (boolean, string?)
    return UpdateCurrentLanguage(Language, true);
end;

--[[
    Returns the language that is currently being used
    as a fallback language.
--]]
function LanguageManager:GetCurrentFallbackLanguage(): string
    return LanguageManager.CurrentFallbackLanguage;
end;

--[[
    Gets the localized string for the current language.
    Will return a blank string if no language is loaded.
    Will return the key passed in if the current language
    does not have a translation for it and no fallback is set,
    or if the fallback language does not have one either.
--]]
function LanguageManager:GetString(Key: string): string
    -- Check if there's even a language loaded
    if (LanguageManager.CurrentLanguage == "") then return ""; end;

    -- Check if we need to fallback
    if (LanguageManager.CurrentLanguageDecoded[Key] == nil) then
        if (LanguageManager.CurrentFallbackLanguageDecoded[Key] == nil) then
            return Key;
        else
            return LanguageManager.CurrentFallbackLanguageDecoded[Key];
        end;
    end;

    return LanguageManager.CurrentLanguageDecoded[Key];
end;

--[[
    Gets the localized string for the current language,
    and then formats it with the specified arguments.
    Will return a blank string if no language is loaded.
    Will return the key passed in if the current language
    does not have a translation for it and no fallback is set, 
    or if the fallback language does not have one either.

    The fallback string will also be formatted.
--]]
function LanguageManager:GetStringFormatted(Key: string, ...: any): string
    -- Check if there's even a language loaded
    if (LanguageManager.CurrentLanguage == "") then return ""; end;

    -- Check if we need to fallback
    if (LanguageManager.CurrentLanguageDecoded[Key] == nil) then
        if (LanguageManager.CurrentFallbackLanguageDecoded[Key] == nil) then
            return Key;
        else
            return string.format(LanguageManager.CurrentFallbackLanguageDecoded[Key], ...);
        end;
    end;

    return string.format(LanguageManager.CurrentLanguageDecoded[Key], ...);
end;

--[[
    Returns whether or not the specified key exists in
    the current loaded language.
--]]
function LanguageManager:DoesStringExist(Key: string): boolean
    if (LanguageManager.CurrentLanguage == "") then return false; end;
    return LanguageManager.CurrentLanguageDecoded[Key] ~= nil;
end;

--[[
    Returns whether or not the specified key exists in
    the current loaded fallback language.
--]]
function LanguageManager:DoesFallbackStringExist(Key: string): boolean
    if (LanguageManager.CurrentFallbackLanguage == "") then return false; end;
    return LanguageManager.CurrentFallbackLanguageDecoded[Key] ~= nil;
end;

--[[
    Returns the table of decoded translations for the
    current loaded language.
--]]
function LanguageManager:GetCurrentLanguageDecoded(): {} | nil
    return LanguageManager.CurrentLanguageDecoded;
end;

--[[
    Returns the table of decoded translations for the
    current loaded fallback language.
--]]
function LanguageManager:GetCurrentFallbackLanguageDecoded(): {} | nil
    return LanguageManager.CurrentFallbackLanguageDecoded;
end;

return LanguageManager;
