require'Zenitha'

Zenitha.setAppName('similariddle')
Zenitha.setVersionText(require"version".appVer)
Zenitha.setFirstScene('menu')
Zenitha.setMaxFPS(40) -- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)
Zenitha.setOnFnKeys({NULL, NULL, NULL, NULL, NULL, NULL, love._openConsole})

love.keyboard.setKeyRepeat(true)
if MOBILE then
    love.window.setFullscreen(true)
end

SCR.setSize(1000, 600)
SCN.setDefaultSwap('fastFade')

FONT.setDefaultFont('main')
FONT.load('main','codePixel Regular.ttf')

WIDGET._prototype.button.cornerR=0

--[[题目代码生成流程：
    ace
    bace
    1024(b26)
    17632
    [X]=17632
    非ABC的倍数[X]
    找到13000以上的大指数p*X使得mod ABC分别是游戏参数
    输出hex(n*X)
]]

-- Options
Options={
    name={
        lib={'CET4','CET6','TEM8','GRE'},
        len={'Short','Medium','Long','Loooooong'},
        model={'Easy','Medium','Hard','Extreme','Hell'},
    },
    lengthLevel={
        {4,6},
        {7,9},
        {10,12},
        {13,62},
    },
    matchRateFunc={
        function(len,d) return 1/(math.abs(d)+1) end, -- Arithmetic typewriter
        function(len,d) return 1-math.abs(d)/len/2 end, -- Graceful failure
        function(len,d) return math.max(1-math.abs(d)/3,0) end, -- Trisected principle
        function(len,d) return 0 end, -- stable maintenance
        function(len,d) return 0 end, -- stable maintenance
        function(len,d) return 0 end, -- stable maintenance
    },
}

-- Load data
Primes={2} do
    local n=3
    while n<=62000 do
        local isPrime=true
        for i=1,#Primes do if n%Primes[i]==0 then isPrime=false break end end
        if isPrime then table.insert(Primes,n) end
        n=n+2
    end
end
ABC={} for i=1,385 do if i%5~=0 and i%7~=0 and i%11~=0 then table.insert(ABC,i) end end
WordLib={
    STRING.split(FILE.load('lib_cet4.txt','-string'),'\r\n'),
    STRING.split(FILE.load('lib_cet6.txt','-string'),'\r\n'),
    STRING.split(FILE.load('lib_tem8.txt','-string'),'\r\n'),
    STRING.split(FILE.load('lib_gre.txt','-string'),'\r\n'),
    FULL=STRING.split(FILE.load('lib_full.txt','-string'),'\r\n'),
}
WordHashMap={}
for name,lib in next,WordLib do
    for i=1,#lib do WordHashMap[lib[i]]=name end
end
collectgarbage()

-- Game functions
function NewGame_fixed(word,lib,len,model)
    SCN.go('play',nil,{
        fixed=true,
        word=word,
        lib=lib,
        len=len,
        model=model,
    })
end
function NewGame(lib,len,model)
    local wordLib=WordLib[lib]
    math.randomseed(os.time())
    local word
    repeat
        word=wordLib[math.random(1,#wordLib)]
    until #word>=Options.lengthLevel[len][1] and #word<=Options.lengthLevel[len][2]
    SCN.go('play',nil,{
        fixed=false,
        word=word,
        lib=lib,
        len=len,
        model=model,
    })
end
function PlayFromCode(code)
    local dataNum=tonumber(code,16)
    -- print("number: "..dataNum)
    assert(dataNum and dataNum>0)
    local _lib=dataNum%5
    local _len=dataNum%7
    local _model=dataNum%11
    -- print("lib: ".._lib)
    -- print("len: ".._len)
    -- print("model: ".._model)
    local _id
    for i=1548,#Primes do
        if dataNum%Primes[i]==0 then
            _id=dataNum/Primes[i]
            -- print("find prime: "..Primes[i])
            break
        end
    end
    -- print("abc: ".._id)
    _id=TABLE.find(ABC,_id%385)+math.floor(_id/385)*240
    -- print("id: ".._id)
    local word=WordLib[_lib][_id]
    -- print("word: "..word)
    NewGame_fixed(word,_lib,_len,_model)
    MSG.new('check',"Riddle code loaded!")
end

-- Title
TitleString="Similariddle"
FakeTitleString="Similariddle"
math.randomseed(tonumber(os.date('%Y%m%d')))
repeat
    local r=math.random(3)
    if r==1 then
        -- change a letter to another
        local changePos=math.random(2,#FakeTitleString-1)
        local pick=math.random(2,#FakeTitleString)
        FakeTitleString=
            FakeTitleString:sub(1,changePos-1)..
            FakeTitleString:sub(pick,pick)..
            FakeTitleString:sub(changePos+1)
    elseif r==2 then
        -- repeat a letter
        local changePos=math.random(2,#FakeTitleString-1)
        FakeTitleString=
            FakeTitleString:sub(1,changePos)..
            FakeTitleString:sub(changePos+1)
    elseif r==3 then
        -- swap two letters
        local changePos=math.random(2,#FakeTitleString-2)
        FakeTitleString=
            FakeTitleString:sub(1,changePos-1)..
            FakeTitleString:sub(changePos+1,changePos+1)..
            FakeTitleString:sub(changePos,changePos)..
            FakeTitleString:sub(changePos+2)
    end
until FakeTitleString~=TitleString

-- Load scene files from SOURCE ONLY
for _, v in next, love.filesystem.getDirectoryItems('scenes') do
    if FILE.isSafe('scenes/' .. v) then
        local sceneName=v:sub(1, -5)
        SCN.add(sceneName, require('scenes.' .. sceneName))
    end
end
