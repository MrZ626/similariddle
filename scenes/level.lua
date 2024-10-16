local scene={}

local levelData={
    {"hello","world","w1-3","w1-4","w1-5","w1-6"},
    {"w2-1","second","w2-3","w2-4","w2-5","w2-6"},
    {"w3-1","w3-2","w3-3","w3-4","w3-5","w3-6"},
    {"w4-1","w4-2","w4-3","w4-4","w4-5","w4-6"},
    {"w5-1","w5-2","w5-3","w5-4","w5-5","w5-6"},
    {"w6-1","w6-2","w6-3","w6-4","w6-5","w6-6"},
}

local function levelPlayable(i)
    if i==1 then
        return true
    elseif i<=6 then
        return GameData.levelPass[i-1]==1
    elseif i%6==1 then
        return GameData.levelPass[i-6]==1
    else
        return GameData.levelPass[i-1]==1 or GameData.levelPass[i-6]==1 or GameData.levelPass[i-7]==1
    end
end
local function playLevel(word,model,levelID)
    if not levelPlayable(levelID) then return end
    StartGame{
        daily=false,
        fixed=true,
        word=word,
        model=model,
        lib=0,len=0,
        levelID=levelID,
    }
end

function scene.load()
    for i=1,36 do
        local W=scene.widgetList[i]
        W.color=GameData.levelPass[i]==1 and 'G' or (levelPlayable(i) and 'L' or 'D')
        W:reset()
    end
end

scene.widgetList={
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
for L=1,6 do
    for l=1,6 do
        local id=(L-1)*6+l
        table.insert(scene.widgetList,id,WIDGET.new{
            type='button_fill',pos={.5,.5},
            text=L..'-'..l,
            x=(l-3.5)*90,
            y=(L-3.5)*90,
            w=80,
            code=function() playLevel(levelData[L][l],L,id) end,
        })
    end
end

return scene
