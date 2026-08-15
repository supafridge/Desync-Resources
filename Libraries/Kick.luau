-- cloneref is optional, just here for anti-cheat reasons
local TextService: TextService  = cloneref(game:GetService("TextService"));
local CoreGui: CoreGui          = cloneref(game:GetService("CoreGui"));
local Players: Players          = cloneref(game:GetService("Players"));

local LocalPlayer: Player       = Players.LocalPlayer;

-- Prompt stuff
local PromptOverlay             = CoreGui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay");
local DisconnectPrompt: Frame   = nil;
local TitleLabel: TextLabel     = nil;
local ErrorMessage: TextLabel   = nil;

-- Stolen straight from CoreGui.RobloxGui.Modules.ErrorPrompt, I just added variable names and did some clean-up
local function CalculateResizeHeight(Prompt: Frame): number
    local ErrorMessage: TextLabel           = Prompt:WaitForChild("MessageArea"):WaitForChild("ErrorFrame"):WaitForChild("ErrorMessage");

    -- Magical resizing calculations
    local FrameSize: Vector2                = Vector2.new(Prompt.Size.X.Offset - 40, 1_000);
    local TextSize: Vector2                 = TextService:GetTextSize(ErrorMessage.Text, ErrorMessage.TextSize,
        ErrorMessage.Font, FrameSize);
    local CalculatedFrameHeight: number     = math.min(TextSize.Y + 148, math.huge);
    local ResizeHeight: number              = math.max(CalculatedFrameHeight, 250);

    return ResizeHeight;
end;

local function Kick(Title: string, Message: string)
    PromptOverlay.ChildAdded:Once(function()
        -- Get ErrorPrompt labels
        DisconnectPrompt        = PromptOverlay:WaitForChild("ErrorPrompt");
        TitleLabel              = DisconnectPrompt:WaitForChild("TitleFrame"):WaitForChild("ErrorTitle");
        ErrorMessage            = DisconnectPrompt:WaitForChild("MessageArea"):WaitForChild("ErrorFrame"):WaitForChild("ErrorMessage");

        -- Update prompt TextLabels
        task.wait(); -- This is needed (trust me)
        TitleLabel.Text         = Title;
        ErrorMessage.Text       = Message;
        DisconnectPrompt.Size   = UDim2.new(0, DisconnectPrompt.Size.X.Offset, 0, CalculateResizeHeight(DisconnectPrompt));
    end);
    
    LocalPlayer:Kick();
end;

-- Kick("Custom Title", "Custom kick message");
return Kick;