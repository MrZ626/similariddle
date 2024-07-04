local function playDaily()
    local day=os.date("!%Y")*366+os.date("!%j")
    math.randomseed(day)
    for _=1,26 do math.random() end
    local lib=MATH.randFreq{7,2,1,0}
    local wordLib=WordLib[lib]
    SCN.go('play',nil,{
        daily=true,
        fixed=true,
        word=wordLib[math.random(1,#wordLib)],
        lib=lib,
        len=MATH.randFreq{6,10,3,1},
        model=MATH.randFreq{6,4,3,2,1},
    })
end

-- for day=-10,10 do
--     math.randomseed(2024*366+day)
--     for _=1,26 do math.random() end
--     local lib=MATH.randFreq{7,2,1,0}
--     local wordLib=WordLib[lib]
--     print(wordLib[math.random(1,#wordLib)])
-- end

local scene={}

function scene.load()
    CheckDate()
end

function scene.keyDown(key,isRep)
    if isRep then return true end
    if key=='escape' then
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",1)
        else
            ZENITHA._quit('fade')
        end
    elseif key=='f6' then
        pcall(love._openConsole)
    end
    return true
end

function scene.draw()
    FONT.set(80)
    GC.mStr(GameData.dailyPassed and FakeTitleString or TitleString,500,120)
    FONT.set(35)
    GC.mStr("By MrZ & Staffhook",500,220)
    FONT.set(30)
    if GameData.dailyCount>0 then
        GC.printf(GameData.dailyCount,350-130,430,260,'right')
    end
    if GameData.dailyPassed then
        GC.setColor(.62,.9,.42)
        GC.print("Pass",350-130,430)
    end
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=350,y=380,w=260,h=90,fontSize=45,text="Daily",code=playDaily},
    WIDGET.new{type='button_fill',x=650,y=380,w=260,h=90,fontSize=45,text="Custom",code=WIDGET.c_goScn'custom'},
    WIDGET.new{type='button_fill',pos={1,1},text='Quit',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
return scene
