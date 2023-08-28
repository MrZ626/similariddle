local lib=1
local len=1
local mode=1

local function playFromCode()
    local data=love.system.getClipboardText()
    if not data then return MSG.new('warn','No data in clipboard') end
    local dataNum=tonumber(data,16)
    if not (dataNum and dataNum>0) then return MSG.new('warn','Invalid data') end
    local _lib=dataNum%5+1
    local _len=dataNum%7+1
    local _mode=dataNum%11+1
    local _id
    for i=1,#Primes do
        if dataNum%Primes[i]==0 then
            _id=dataNum/Primes[i]
            break
        end
    end
    local libName=Options.name.lib[_lib]
    local word=WordLib[libName][TABLE.find(WordNumber[libName],_id)]

    SCN.go('play',nil,{
        word=word,
        lib=libName,
        len=Options.name.len[_len],
        mode=Options.name.mode[_mode],
    })
end
local function play()
    local wordLib=WordLib[Options.name.lib[lib]]
    math.randomseed(os.time())
    SCN.go('play',nil,{
        word=wordLib[math.random(1,#wordLib)],
        lib=Options.name.lib[lib],
        len=Options.name.len[len],
        mode=Options.name.mode[mode],
    })
end

local scene={}

function scene.draw()
    FONT.set(80)
    GC.mStr("Custom",500,60)
end

scene.widgetList={
    WIDGET.new{type='slider',x=250,y=220,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return lib end,valueShow=function(s) return Options.name.lib[s._pos0] end,code=function(i) lib=i end},
    WIDGET.new{type='slider',x=250,y=300,w=500,axis={1,4,1},labelDistance=40,textAlwaysShow=true,disp=function() return len end,valueShow=function(s) return Options.name.len[s._pos0] end,code=function(i) len=i end},
    WIDGET.new{type='slider',x=250,y=380,w=500,axis={1,5,1},labelDistance=40,textAlwaysShow=true,disp=function() return mode end,valueShow=function(s) return Options.name.mode[s._pos0] end,code=function(i) mode=i end},
    WIDGET.new{type='button_fill',x=150,y=500,w=80,fontSize=25,color='lB',text="Code",code=playFromCode},
    WIDGET.new{type='button_fill',x=350,y=500,w=260,h=90,fontSize=50,text="Start",code=play},
    WIDGET.new{type='button_fill',x=650,y=500,w=260,h=90,fontSize=50,text="Back",code=WIDGET.c_backScn()},
}
return scene
