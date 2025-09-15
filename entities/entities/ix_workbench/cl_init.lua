include("shared.lua")

if (CLIENT) then
    netstream.Hook("ixWorkbench_Open", function()
        if (IsValid(ix.gui.workbench)) then
            ix.gui.workbench:Remove() -- close old one
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 300)
        frame:Center()
        frame:SetTitle("Workbench")
        frame:MakePopup()

        ix.gui.workbench = frame -- store globally so it doesn't spawn 100x
    end)
end
