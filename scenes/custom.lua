local optionNames={
    lib={'CET4','CET6','TEM8','GRE'},
    len={'Short','Medium','Long','Loooooong'},
    model={'Easy','Medium','Hard','Extreme','Hell'},
}

local lib=1
local len=1
local model=1

local scene={}

function scene.draw()
    FONT.set(80)
    GC.mStr("Custom",500,60)
end

scene.widgetList={
    WIDGET.new{type='slider',x=250,y=220,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return lib end,valueShow=function(s) return optionNames.lib[s._pos0] end,code=function(i) lib=i end},
    WIDGET.new{type='slider',x=250,y=300,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return len end,valueShow=function(s) return optionNames.len[s._pos0] end,code=function(i) len=i end},
    WIDGET.new{type='slider',x=250,y=380,w=500,axis={1,5,1},labelDistance=40,textAlwaysShow=true,disp=function() return model end,valueShow=function(s) return optionNames.model[s._pos0] end,code=function(i) model=i end},
    WIDGET.new{type='button_fill',x=150,y=500,w=80,fontSize=25,color='lB',text="Code",code=function()
        local code=love.system.getClipboardText()
        if code then code=STRING.trim(code) end
        if not pcall(PlayFromCode,code) then
            MSG.new('error',"Invalid riddle code: "..(code and #code>0 and code or "?"),1)
        end
    end},
    WIDGET.new{type='button_fill',x=350,y=500,w=260,h=90,fontSize=50,text="Start",code=function() NewGame(lib,len,model) end},
    WIDGET.new{type='button_fill',x=650,y=500,w=260,h=90,fontSize=50,text="Back",code=WIDGET.c_backScn()},
}
return scene
