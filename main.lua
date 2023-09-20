require'Zenitha'

Zenitha.setAppName('similariddle')
Zenitha.setVersionText(require"version".string)
Zenitha.setFirstScene('menu')
Zenitha.setMaxFPS(40) -- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)
Zenitha.setOnFnKeys({NULL,NULL,NULL,NULL,NULL,NULL,love._openConsole})

love.keyboard.setKeyRepeat(true)
if MOBILE then
    love.window.setFullscreen(true)
end

STRING.install()
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

do -- Load words
    local Primes={2}
    do
        local n=3
        while n<=62000 do
            local isPrime=true
            for i=1,#Primes do
                if n%Primes[i]==0 then
                    isPrime=false
                    break
                end
            end
            if isPrime then table.insert(Primes,n) end
            n=n+2
        end
    end
    local ABC={}
    for i=1,385 do if i%5~=0 and i%7~=0 and i%11~=0 then table.insert(ABC,i) end end
    WordLib={
        FILE.load('lib_cet4.txt','-string'):split('\r\n'),
        FILE.load('lib_cet6.txt','-string'):split('\r\n'),
        FILE.load('lib_tem8.txt','-string'):split('\r\n'),
        FILE.load('lib_gre.txt','-string'):split('\r\n'),
        FILE.load('lib_full.txt','-string'):split('\r\n'),
    }
    WordHashMap={}
    AnswerWordList={} -- Temp list, for sorting by simmilarity
    for libID,lib in next,WordLib do
        for i=1,#lib do
            lib[i]=lib[i]:lower()
            if not WordHashMap[lib[i]] then
                WordHashMap[lib[i]]=libID
                if libID<5 then
                    table.insert(AnswerWordList,{lib[i]})
                end
            end
        end
    end
    collectgarbage()

    -- local finding="aux"
    -- local count=0
    -- for i=1,#AnswerWordList do
    --     if AnswerWordList[i][1]:sub(-#finding)==finding then
    --         print(AnswerWordList[i][1])
    --         count=count+1
    --     end
    -- end
    -- print(count)

    function GenerateCode(data)
        -- print("word: "..data.word)
        -- print("lib: "..data.lib)
        -- print("len: "..data.len)
        -- print("model: "..data.model)
        local id=TABLE.findOrdered(WordLib[data.lib],data.word)
        -- print("id: "..id)
        local abc=0
        while not ABC[id] do
            abc=abc+385
            id=id-240
        end
        abc=abc+ABC[id]
        -- print("abc: "..abc)

        local pid=1547
        local p
        repeat
            pid=pid+1
            p=Primes[pid]*abc
        until p%5==data.lib and p%7==data.len and p%11==data.model
        -- print("find prime: "..Primes[pid])
        -- print("result: "..p)
        -- print(string.format("hex: %x",p))
        return string.format("%x",p)
    end
    function ParseCode(code)
        -- print("Importing code: "..code)
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
        _id=TABLE.findOrdered(ABC,_id%385)+math.floor(_id/385)*240
        -- print("id: ".._id)
        local word=WordLib[_lib][_id]
        -- print("word: "..word)
        return {
            fixed=true,
            word=word,
            lib=_lib,
            len=_len,
            model=_model,
        }
    end
end
do -- Game code
    local LengthLevel={
        {4,6},
        {7,9},
        {10,12},
        {13,62},
    }
    function NewGame(lib,len,model)
        local wordLib=WordLib[lib]
        math.randomseed(os.time())
        local word
        repeat
            word=wordLib[math.random(1,#wordLib)]
        until #word>=LengthLevel[len][1] and #word<=LengthLevel[len][2]
        SCN.go('play',nil,{
            daily=false,
            fixed=false,
            word=word,
            lib=lib,
            len=len,
            model=model,
        })
    end

    local function combMatch(model,s1,s2)
        assert(#s1==#s2,"strComp(s1,s2): #s1!=#s2")
        local len=#s1
        local t1,t2={},{}
        for i=1,len do
            t1[i]=s1:sub(i,i)
            t2[i]=s2:sub(i,i)
        end
        local score=0
        for i=1,len do
            for _=0,1 do -- for swap t1 and t2 then try again
                local n=0
                while true do
                    if t1[i]==t2[i+n] then
                        -- if love.keyboard.isDown('lshift') then print(modelFunc(len,n)) end
                        -- score=score+modelFunc(len,n)
                        if model==1 then
                            -- Trisected principle
                            score=score+math.max(1-math.abs(n)/3,0)
                        elseif model==2 then
                            -- Arithmetic typewriter
                            score=score+1/(math.abs(n)+1)
                        elseif model==3 then
                            -- Pirate ship
                            local decay,weight
                            if i==1 or i==#t1 then
                                decay,weight=1.5,3
                            elseif i==2 or i==#t1-1 then
                                decay,weight=3,2
                            else
                                decay,weight=6,1
                            end

                            score=score+math.max(1-math.abs(n)/decay,0)*weight
                        elseif model==4 then
                            -- Weaving logic (not implemented here)
                        elseif model==5 then
                            -- Graceful failure
                            score=score+1-math.abs(n)/len/2
                        elseif model==6 then
                            -- Stable maintenance (not designed yet)
                            score=0
                        end
                        break
                    end
                    n=n<1 and -n+1 or -n -- 0,-1,1,-2,2,...
                    if n>=len then
                        break
                    end
                end
                t1,t2=t2,t1 -- swap
            end
        end
        if model==3 then
            local totalWeight=3+2+(len-4)+2+3
            score=score/totalWeight*len
        end
        return score/len/2
    end
    local function editDist(s1,s2) -- By Copilot
        local len1,len2=#s1,#s2
        local t1,t2={},{}
        for i=1,len1 do t1[i]=s1:sub(i,i) end
        for i=1,len2 do t2[i]=s2:sub(i,i) end

        local dp={}
        for i=0,len1 do dp[i]=TABLE.new(0,len2) end
        dp[0][0]=0
        for i=1,len1 do dp[i][0]=i end
        for i=1,len2 do dp[0][i]=i end

        for i=1,len1 do
            for j=1,len2 do
                dp[i][j]=t1[i]==t2[j] and dp[i-1][j-1] or math.min(dp[i-1][j],dp[i][j-1],dp[i-1][j-1])+1
            end
        end
        return dp[len1][len2]
    end
    function GetSimilarity(model,w1,w2)
        local final
        if model==4 then
            local dist=editDist(w1,w2)
            final=1-(dist/#w1+dist/#w2)/2
        else
            local maxSimilarity=-1e99
            local short,long=#w1<#w2 and w1 or w2,#w1<#w2 and w2 or w1

            for i=1,#long-#short+1 do
                maxSimilarity=math.max(maxSimilarity,combMatch(model,short,long:sub(i,i+#short-1))-(#long-#short)/#long)
            end
            final=maxSimilarity
        end
        return final-final%2^-26
    end
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
    if FILE.isSafe('scenes/'..v) then
        local sceneName=v:sub(1,-5)
        SCN.add(sceneName,require('scenes.'..sceneName))
    end
end
