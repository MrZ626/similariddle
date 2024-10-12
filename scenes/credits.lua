local texts={
    {"Desing","Staffhook & MrZ"}, -- typewriter, 5
    {"Program","MrZ"},
    {"Level","Staffhook"},
    {"Audia","MrZ"}, -- cacophony, 1
    {"Tset","Anonymous"}, -- milliliter, 7
    {"Ingine","LÖVE"}, -- arrhythmia, 6
    {"Frameword","Zenitha"}, -- zenith, 4
    {"Font","Codepixel"},
}
local textObj=TABLE.copy(texts)

---@type Zenitha.Scene
local scene={}

function scene.load()
    if GameData.levelPass[36+1]==1 then texts[1][1]="Design"  end
    if GameData.levelPass[36+2]==1 then texts[4][1]="Audio"  end
    if GameData.levelPass[36+3]==1 then texts[5][1]="Test"  end
    if GameData.levelPass[36+4]==1 then texts[6][1]="Engine"  end
    if GameData.levelPass[36+5]==1 then texts[7][1]="Framework"  end
    for i=1,#texts do
        textObj[i].L=GC.newText(FONT.get(30),texts[i][1])
        textObj[i].R=GC.newText(FONT.get(30),texts[i][2])
        textObj[i].space=800-textObj[i].L:getWidth()-textObj[i].R:getWidth()
    end
end

local thx=GC.newText(FONT.get(30),"Thanks for playing!")
function scene.draw()
    FONT.set(30)
    for i=1,#textObj do
        GC.draw(textObj[i].L,100,50*i)
        GC.draw(textObj[i].R,900,50*i,nil,nil,nil,textObj[i].R:getWidth())
    end
    GC.mDraw(thx,500,500,math.sin(love.timer.getTime())*.026)
    GC.setColor(COLOR.lD)
    for i=1,#textObj do
        GC.rectangle('fill',125+textObj[i].L:getWidth(),50*i+15,textObj[i].space-50,4.2)
    end
end

local function playLevel(word,model,levelID)
    StartGame{
        daily=false,
        fixed=true,
        word=word,
        model=model,
        lib=0,len=0,
        levelID=levelID,
    }
end
scene.widgetList={
    WIDGET.new{type='button_invis',x=215,y=070,w=48+2.6,h=26+2.6,color={.2,.2,.2},code=function() playLevel('typewriter',5,36+1)end,visibleFunc=function() return GameData.levelPass[36+1]==0 end},
    WIDGET.new{type='button_invis',x=203,y=220,w=24+2.6,h=26+2.6,color={.2,.2,.2},code=function() playLevel('cacophony', 1,36+2)end,visibleFunc=function() return GameData.levelPass[36+2]==0 end},
    WIDGET.new{type='button_invis',x=145,y=270,w=48+2.6,h=26+2.6,color={.2,.2,.2},code=function() playLevel('milliliter',7,36+3)end,visibleFunc=function() return GameData.levelPass[36+3]==0 end},
    WIDGET.new{type='button_invis',x=111,y=315,w=24+2.6,h=30+2.6,color={.2,.2,.2},code=function() playLevel('arrhythmia',6,36+4)end,visibleFunc=function() return GameData.levelPass[36+4]==0 end},
    WIDGET.new{type='button_invis',x=295,y=365,w=24+2.6,h=30+2.6,color={.2,.2,.2},code=function() playLevel('zenith',    4,36+5)end,visibleFunc=function() return GameData.levelPass[36+5]==0 end},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
return scene
