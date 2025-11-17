EdithVestige = RegisterMod("Edith: Vestige", 1) --[[@as ModReference|table]]
EdithVestige.Version = "v1.0.5"

if not REPENTOGON then 
    local font = Font()
    font:Load("font/pftempestasevencondensed.fnt")

    EdithVestige:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local text = "REPENTOGON is missing"
        local text2 = "check repentogon.com"
        local color = KColor(2,.5,.5,1)
        font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, color, 1, true )
        font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, color, 1, true )
    end)
    return
end

include("resources.scripts.libs.EdithKotryJumpLib").Init(EdithVestige)
include("include")