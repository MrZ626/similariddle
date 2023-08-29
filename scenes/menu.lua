local function playDaily()
    local day=os.date("%Y")*366+os.date("%j")
    math.randomseed(day)
    local lib=MATH.randFreq{7,2,1,0}
    local len=MATH.randFreq{3,5,4,3}
    local model=MATH.randFreq{6,4,3,2,1}
    local wordLib=WordLib[lib]
    local word=wordLib[math.random(1,#wordLib)]
    NewGame_fixed(word,lib,len,model)
end

local scene={}

function scene.draw()
    FONT.set(80)
    GC.mStr(TitleString,500,120)
    FONT.set(35)
    GC.mStr("By MrZ & Staffhook",500,220)
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=350,y=380,w=260,h=90,fontSize=45,text="Daily",code=playDaily},
    WIDGET.new{type='button_fill',x=650,y=380,w=260,h=90,fontSize=45,text="Custom",code=WIDGET.c_goScn'custom'},
}
return scene
