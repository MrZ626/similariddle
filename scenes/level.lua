local scene={}

local levelData={
    {
        "hello",
        "world",
        "symphony",
        "scramble", -- favorski
        "subterranean",
        "suffocate",
    },
    {
        "second",
        "blackboard",
        "restaurant",
        "stagnant",
        "scrutiny", -- zqh
        "amalgam",
    },
    {
        "similarity",
        "unlucky",
        "auxiliary",
        "enthusiasm",
        "camouflage",
        "besmirch",
    },
    {
        "sticky",
        "sacrifice", -- grass
        "calendar",
        "deluxe",
        "equinox",
        "fulcrum",
    },
    {
        "teenager",
        "decrease",
        "souvenir", -- iscream
        "perimeter",
        "flamboyant",
        "cornucopia",
    },
    {
        "eight",
        "advertisement",
        "diagnose",
        "monochrome",
        "repertoire",
        "soliloquy", -- nbrige
    },
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
