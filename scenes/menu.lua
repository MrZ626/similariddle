local function playDaily()
    local day=os.date("%Y")*366+os.date("%j")
    math.randomseed(day)
    for _=1,26 do math.random() end
    local lib=MATH.randFreq{7,2,1,0}
    local wordLib=WordLib[lib]
    SCN.go('play',nil,{
        fixed=true,
        word=wordLib[math.random(1,#wordLib)],
        lib=lib,
        len=MATH.randFreq{6,10,3,1},
        model=MATH.randFreq{6,4,3,2,1},
    })
end

local scene={}

function scene.keyDown(key,isRep)
    if isRep then return end
    if key=='escape' then
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",1)
        else
            Zenitha._quit('fade')
        end
    end
end

function scene.draw()
    FONT.set(80)
    GC.mStr(TitleString,500,120)
    FONT.set(35)
    GC.mStr("By MrZ & Staffhook",500,220)
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=350,y=380,w=260,h=90,fontSize=45,text="Daily",code=playDaily},
    WIDGET.new{type='button_fill',x=650,y=380,w=260,h=90,fontSize=45,text="Custom",code=WIDGET.c_goScn'custom'},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
return scene
