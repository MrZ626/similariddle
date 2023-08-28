local lib=1
local len=1
local mode=1

local function play()
    SCN.go('play',nil,lib,len,mode)
end

local scene={}

function scene.draw()
    FONT.set(80)
    GC.mStr("Custom",500,60)
end

scene.widgetList={
    WIDGET.new{type='slider',x=250,y=220,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return lib end,valueShow=function(s) return OptionNames[1][s._pos0] end,code=function(i) lib=i end},
    WIDGET.new{type='slider',x=250,y=300,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return len end,valueShow=function(s) return OptionNames[2][s._pos0] end,code=function(i) len=i end},
    WIDGET.new{type='slider',x=250,y=380,w=500,axis={1,5,1},labelDistance=40,textAlwaysShow=true,disp=function() return mode end,valueShow=function(s) return OptionNames[3][s._pos0] end,code=function(i) mode=i end},
    WIDGET.new{type='button_fill',x=350,y=500,w=260,h=90,fontSize=50,text="Start",code=play},
    WIDGET.new{type='button_fill',x=650,y=500,w=260,h=90,fontSize=50,text="Back",code=WIDGET.c_backScn()},
}
return scene
