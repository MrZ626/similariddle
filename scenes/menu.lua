-- for day=-10,10 do
--     math.randomseed(2024*366+day)
--     for _=1,26 do math.random() end
--     local lib=MATH.randFreq{7,2,1,0}
--     local wordLib=WordLib[lib]
--     print(TABLE.getRandom(wordLib))
-- end

local scene={}

function scene.load()
    CheckDate()
    scene.widgetList.credits.color=table.concat(TABLE.sub(GameData.levelPass,37,41))=='11111' and 'G' or 'L'
    scene.widgetList.credits:reset()
end

function scene.keyDown(key,isRep)
    if isRep then return true end
    if key=='escape' then
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",1)
        else
            ZENITHA._quit('fade')
        end
    elseif key=='c' then
        SCN.go('credits')
    elseif key=='f6' then
        pcall(love._openConsole)
    end
    return true
end

function scene.draw()
    FONT.set(80)
    GC.mStr(GameData.dailyPassed and FakeTitleString or TitleString,500,80)
    FONT.set(35)
    GC.mStr("By MrZ & Staffhook",500,180)
    FONT.set(30)
    if GameData.dailyCount>0 then
        GC.printf(GameData.dailyCount,350-130,495,240,'right')
    end
    if GameData.dailyPassed then
        GC.setColor(.62,.9,.42)
        GC.print("Pass",350-130,495)
    end
end

scene.widgetList={
    WIDGET.new{type='button_fill',x=500,y=310,w=260,h=90,fontSize=45,text="Level",code=WIDGET.c_goScn'level'},
    WIDGET.new{type='button_fill',x=350,y=430,w=260,h=90,fontSize=45,text="Daily",code=function()
        local day=os.date("!%Y")*366+os.date("!%j")
        math.randomseed(day)
        for _=1,26 do math.random() end
        local lib=MATH.randFreq{7,2,1,0}
        local wordLib=WordLib[lib]
        StartGame{
            daily=true,
            fixed=true,
            word=TABLE.getRandom(wordLib),
            lib=lib,
            len=MATH.randFreq{6,10,3,1},
            model=MATH.randFreq{6,4,3,2,1},
        }
    end},
    WIDGET.new{type='button_fill',x=650,y=430,w=260,h=90,fontSize=45,text="Custom",code=WIDGET.c_goScn'custom'},
    WIDGET.new{type='button_fill',name='credits',pos={0,1},text='Credits',x= 80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'c'},
    WIDGET.new{type='button_fill',pos={1,1},color='lR',text='Quit',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
return scene
