require'Zenitha'

Zenitha.setAppName('similariddle')
Zenitha.setVersionText(require"version".appVer)
Zenitha.setFirstScene('menu')
Zenitha.setMaxFPS(40) -- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)
Zenitha.setOnFnKeys({NULL,NULL,NULL,NULL,NULL,NULL,love._openConsole})

love.keyboard.setKeyRepeat(true)
if MOBILE then
    love.window.setFullscreen(true)
end

SCR.setSize(1000,600)
SCN.setDefaultSwap('none')

FONT.setDefaultFont('main')
FONT.load('main','codePixel Regular.ttf')

WIDGET._prototype.base._hoverTimeMax=0.01
WIDGET._prototype.base._pressTimeMax=0.01
WIDGET._prototype.button.cornerR=0
WIDGET._prototype.slider.cornerR=0
WIDGET._prototype.slider._approachSpeed=260

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
local ratingModelFunc={
    function(len,d) return math.max(1-math.abs(d)/3,0) end, -- Trisected principle
    function(len,d) return 1/(math.abs(d)+1) end, -- Arithmetic typewriter
    function(len,d) return 0 end, -- Pirates' ship
    NULL, -- Weaving logic
    function(len,d) return 1-math.abs(d)/len/2 end, -- Graceful failure
    function(len,d) return 0 end, -- Stable maintenance
}
local function combMatch(model,s1,s2)
    assert(#s1==#s2,"strComp(s1,s2): #s1!=#s2")
    local len=#s1
    local t1,t2={},{}
    for i=1,len do
        t1[i]=s1:sub(i,i)
        t2[i]=s2:sub(i,i)
    end
    local score=0
    local modelFunc=ratingModelFunc[model]
    for i=1,len do
        for _=0,1 do -- for swap t1 and t2 then try again
            local n=0
            while true do
                n=n<1 and -n+1 or -n -- (0,) -1,1,-2,2,...
                if n>=len then
                    break
                end
                if t1[i]==t2[i+n] then
                    score=score+modelFunc(len,n)
                    break
                end
                n=n+1
            end
            t1,t2=t2,t1 -- swap
        end
    end
    return score/len/2
end
local function editDist(s1,s2) -- By Copilot
    local len1,len2=#s1,#s2
    local t1,t2={},{}
    for i=1,len1 do t1[i]=s1:sub(i,i) end
    for i=1,len2 do t2[i]=s2:sub(i,i) end
    local dp={}
    for i=0,len1 do dp[i]=TABLE.new(0,len2) end dp[0][0]=0
    for i=1,len1 do dp[i][0]=i end
    for i=1,len2 do dp[0][i]=i end
    for i=1,len1 do for j=1,len2 do
        dp[i][j]=t1[i]==t2[j] and dp[i-1][j-1] or math.min(dp[i-1][j],dp[i][j-1],dp[i-1][j-1])+1
    end end
    return dp[len1][len2]
end
function GetSimilarity(model,w1,w2)
    if model==4 then
        local dist=editDist(w1,w2)
        return 1-(dist/#w1+dist/#w2)/2
    else
        local maxSimilarity=-1e99
        local short,long=#w1<#w2 and w1 or w2,#w1<#w2 and w2 or w1

        for i=1,#long-#short+1 do
            maxSimilarity=math.max(maxSimilarity,combMatch(model,short,long:sub(i,i+#short-1))-(#long-#short)/#long)
        end
        return maxSimilarity
    end
end

local LengthLevel={
    {4,6},
    {7,9},
    {10,12},
    {13,62},
}
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
    until #word>=LengthLevel[len][1] and #word<=LengthLevel[len][2]
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
for _,v in next,love.filesystem.getDirectoryItems('scenes') do
    if FILE.isSafe('scenes/' .. v) then
        local sceneName=v:sub(1,-5)
        SCN.add(sceneName,require('scenes.' .. sceneName))
    end
end
