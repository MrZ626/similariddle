local optionNames={
    lib={'CET4','CET6','TEM8','GRE'},
    len={'Short','Medium','Long','Loooooong'},
    model={'Trivial','Easy','Medium','Hard','Extreme','Hell','Truth'},
    algorithm={'Consecutive Prize','Trisected Principle','Arithmetic Typewriter','Pirate Ship','Graceful Failure','Weaving Logic','Stable Maintenance'},
    colors={COLOR.lC,COLOR.lG,COLOR.lY,COLOR.O,COLOR.R,COLOR.M,COLOR.lD},
}

local lib=1
local len=1
local model=1

local scene={}

function scene.draw()
    FONT.set(80)
    GC.mStr("Custom",500,60)
    FONT.set(20)
    local p=scene.widgetList[3]._pos0
    GC.setColor(optionNames.colors[p])
    GC.mStr(optionNames.algorithm[p],500,405)
end

scene.widgetList={
    WIDGET.new{type='slider',x=250,y=220,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return lib   end,valueShow=function(s) return optionNames.lib[s._pos0] end,code=function(i) lib=i end},
    WIDGET.new{type='slider',x=250,y=300,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return len   end,valueShow=function(s) return optionNames.len[s._pos0] end,code=function(i) len=i end},
    WIDGET.new{type='slider',x=250,y=380,w=500,axis={1,7,1},labelDistance=40,textAlwaysShow=true,disp=function() return model end,valueShow=function(s) return optionNames.model[s._pos0] end,code=function(i) model=i end},
    WIDGET.new{type='button_fill',x=450,y=500,w=260,h=90,fontSize=50,text="Start",code=function()
        local LengthLevel={
            {4,6},
            {7,9},
            {10,12},
            {13,62},
        }
        local wordLib=WordLib[lib]
        math.randomseed(os.time())
        local word
        repeat
            word=wordLib[math.random(1,#wordLib)]
        until #word>=LengthLevel[len][1] and #word<=LengthLevel[len][2]
        StartGame{
            daily=false,
            fixed=false,
            word=word,
            lib=lib,
            len=len,
            model=model,
        }
    end},
    WIDGET.new{type='button_fill',x=640,y=500,w=90,fontSize=25,color='lB',text="Code",code=function()
        local code=love.system.getClipboardText()
        if code then code=code:trim() end
        local success,data=pcall(ParseCode,code)
        if success then
            StartGame(data)
            MSG.new('check',"Riddle code loaded!")
        else
            MSG.new('error',"Invalid riddle code: "..(code and #code>0 and code or "?"),1)
        end
    end},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
return scene
