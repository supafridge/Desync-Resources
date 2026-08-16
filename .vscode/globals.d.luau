-- Luarmor runtime variables
declare LRM_ScriptName: string;
declare LRM_ScriptVersion: string;
declare LRM_IsUserPremium: boolean;
declare LRM_SecondsLeft: number;
declare LRM_TotalExecutions: number;
declare LRM_LinkedDiscordID: string;
declare LRM_UserNote: string;

-- Luarmor macros
declare function LRM_SEND_WEBHOOK(URL: string, Data: {})
declare function LRM_SANITIZE(Data: string | () -> string, Expression: string): string

-- Luraph macros
declare function LPH_NO_VIRTUALIZE(Function: () -> any): ()

-- Executor functions
declare function cloneref(Instance: any): any
declare function clonereference(Instance: any): any
declare function newcclosure(Function: any): ()
declare function identifyexecutor(): (string, string?)
declare function getexecutorname(): (string, string?)
declare function queueonteleport()
declare function queue_on_teleport()
declare function clearteleportqueue()
declare function clear_teleport_queue()
declare function clearqueueonteleport()

declare function isfolder(Path: string): boolean
declare function isfile(Path: string): boolean
declare function makefolder(Path: string)
declare function readfile(File: string): string
declare function writefile(File: string, Contents: string)
declare function appendfile(File: string, Contents: string)
declare function listfiles(Path: string): {string}
declare function delfile(File: string)