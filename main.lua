require'Zenitha'

ZENITHA.setAppName('similariddle')
ZENITHA.setVersionText(require"version".string)
ZENITHA.setFirstScene('menu')
ZENITHA.setMaxFPS(40) -- Enough!
ZENITHA.globalEvent.clickFX=NULL
ZENITHA.globalEvent.drawCursor=NULL

love.keyboard.setKeyRepeat(true)
if MOBILE then
    love.window.setFullscreen(true)
end

STRING.install()
SCR.setSize(1000,600)
SCN.setDefaultSwap('none')

FONT.setDefaultFont('main')
FONT.setFilter('main','nearest','nearest')
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

---@class Similariddle.LevelData current game's params (word & settings)
---@field daily boolean
---@field fixed boolean
---@field word string
---@field lib number
---@field len number
---@field model number

---@class Similariddle.word
---@field word string
---@field src string
---@field _score number
---@field _srcScore number

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
    AnsWordHashMap={}

    ---@type Similariddle.word[]
    AnsWordList={} -- Temp list, for sorting by simmilarity
    local libNames={'CET4','CET6','TEM8','GRE'}
    for libID,lib in next,WordLib do
        for i=1,#lib do
            lib[i]=lib[i]:lower()
            if not AnsWordHashMap[lib[i]] then
                AnsWordHashMap[lib[i]]=libID
                if libID<=4 then
                    table.insert(AnsWordList,{
                        word=lib[i],
                        src=libNames[libID],
                        _srcScore=1.1-libID*.1,
                    })
                end
            end
        end
    end
    collectgarbage()

    -- Count how many words end with [finding]
    -- local finding="ing"
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
            daily=false,
            fixed=true,
            word=word,
            lib=_lib,
            len=_len,
            model=_model,
        }
    end
end

do -- Game code
    ---@param data Similariddle.LevelData
    function StartGame(data)
        SCN.go(data.model~=7 and 'play' or 'play_final',nil,data)
    end
    local sub,find,match,byte,rep=string.sub,string.find,string.match,string.byte,string.rep
    local max,min,abs=math.max,math.min,math.abs
    local between=MATH.between
    local ins,rem=table.insert,table.remove
    local function combMatch(model,s1,s2)
        assert(#s1==#s2,"strComp(s1,s2): #s1!=#s2")
        local length=max(#match(s1,'%S+'),#match(s2,'%S+'))
        local t1,t2={},{}
        for i=1,#s1 do
            t1[i]=sub(s1,i,i)
            t2[i]=sub(s2,i,i)
        end
        local score=0
        for i=1,#s1 do
            local n=0
            while true do
                if t1[i]~=' ' and t1[i]==t2[i+n] then
                    if model==1 then
                        -- Consecutive Prize (not implemented here)
                    elseif model==2 then
                        -- Trisected Principle
                        score=score+max(1-(n>=0 and n or -n)/3,0)
                    elseif model==3 then
                        -- Arithmetic Typewriter
                        score=score+1/((n>=0 and n or -n)+1)
                    elseif model==4 then
                        -- Pirate Ship (scoring part)
                        score=score+1/((n>=0 and n or -n)+1)
                    elseif model==5 then
                        -- Graceful Failure
                        score=score+1-(n>=0 and n or -n)/length/2
                    elseif model==6 then
                        -- Weaving Logic (not implemented here)
                    elseif model==7 then
                        -- Stable Maintenance (not designed yet)
                        score=0
                    end
                    break
                end
                n=n<1 and -n+1 or -n -- 0,-1,1,-2,2,...
                if n>length then
                    break
                end
            end
        end
        return score/length
    end
    local function model1comp(ans,try) -- Consecutive Prize
        -- if love.keyboard.isDown('lshift') then
        --     print("."..ans..".","."..try..".")
        -- end

        local total=0

        local tryS,tryE=find(try,'%S+')
        local ansS,ansE=find(ans,'%S+')
        local LEN=max(tryE-tryS+1,ansE-ansS+1)
        for i=tryS,tryE do
            local core=byte(try,i)
            local maxPoint=0
            for j=ansS,ansE do
                if byte(ans,j)==core then
                    local extL,extR=1,1
                    while i-extL>0     and j-extL>0     and byte(try,i-extL)~=32 and byte(try,i-extL)==byte(ans,j-extL) do extL=extL+1 end
                    while i+extR<=#try and j+extR<=#ans and byte(try,i+extR)~=32 and byte(try,i+extR)==byte(ans,j+extR) do extR=extR+1 end
                    local len=extL+extR-1

                    local base=(len+LEN-2)/(len*(len-1)+LEN*(LEN-1))
                    local dist=abs(i-j)+1
                    local point=base/dist
                    if point>maxPoint then
                        -- print(i,j,len,maxPoint.." -> "..point)
                        maxPoint=point
                    end
                end
            end
            total=total+maxPoint
        end
        return total
    end
    local function model5comp(s1,s2) -- Edit distance By Copilot
        local len1,len2=#s1,#s2
        local t1,t2={},{}
        for i=1,len1 do t1[i]=sub(s1,i,i) end
        for i=1,len2 do t2[i]=sub(s2,i,i) end

        local dp={}
        for i=0,len1 do dp[i]=TABLE.new(0,len2) end
        dp[0][0]=0
        for i=1,len1 do dp[i][0]=i end
        for i=1,len2 do dp[0][i]=i end

        for i=1,len1 do
            for j=1,len2 do
                dp[i][j]=t1[i]==t2[j] and dp[i-1][j-1] or min(dp[i-1][j],dp[i][j-1],dp[i-1][j-1])+1
            end
        end
        return dp[len1][len2]
    end
    function GetSimilarity(model,w1,w2)
        if model==4 then
            -- Pirate Ship
            w1=
                rep(sub(w1,1,1),4)..
                rep(sub(w1,2,2),2)..
                (#w1>4 and sub(w1,3,-3) or "")..
                rep(sub(w1,-2,-2),2)..
                rep(sub(w1,-1,-1),4)
            w2=
                rep(sub(w2,1,1),4)..
                rep(sub(w2,2,2),2)..
                (#w2>4 and sub(w2,3,-3) or "")..
                rep(sub(w2,-2,-2),2)..
                rep(sub(w2,-1,-1),4)
        end

        local total=0
        if model==1 then
            -- Consecutive Prize
            local l1,l2=#w1,#w2
            local _w1=(' '):rep(l2-1)..w1
            local _w2=w2..(' '):rep(l1-1)
            for _=1,l1+l2-1 do
                -- print(_w1,_w2,model1comp(_w1,_w2))
                total=max(total,model1comp(_w1,_w2))
                if sub(_w2,-1)==' ' then _w2=' '..sub(_w2,1,-2) else _w1=sub(_w1,2)..' ' end
            end
        elseif model==6 then
            -- Weaving Logic
            local dist=model5comp(w1,w2)
            total=1-(dist/#w1+dist/#w2)/2
        else
            local l1,l2=#w1,#w2
            local _w1=(' '):rep(l2-1)..w1
            local _w2=w2..(' '):rep(l1-1)
            for _=1,l1+l2-1 do
                -- print(_w1,_w2,combMatch(model,_w1,_w2))
                total=max(total,combMatch(model,_w1,_w2))
                if sub(_w2,-1)==' ' then _w2=' '..sub(_w2,1,-2) else _w1=sub(_w1,2)..' ' end
            end
            -- print("T1 ",total)

            local total2=0
            _w1=(' '):rep(l1-1)..w2
            _w2=w1..(' '):rep(l2-1)
            for _=1,l1+l2-1 do
                -- print(_w1,_w2,combMatch(model,_w1,_w2))
                total2=max(total2,combMatch(model,_w1,_w2))
                if sub(_w2,-1)==' ' then _w2=' '..sub(_w2,1,-2) else _w1=sub(_w1,2)..' ' end
            end
            -- print("T2 ",total2)
            total=(total+total2)/2
        end

        -- Length penalty (deprecated)
        -- if model~=5 then
        --     local shortL,longL=#w1,#w2
        --     if shortL>longL then shortL,longL=longL,shortL end
        --     total=total-(longL-shortL)/longL
        -- end

        -- Round total score to 1/2^26
        return total-total%(2^-26)
    end
    -- print(GetSimilarity(1,"expensive","expansive"))
    -- print(GetSimilarity(3,"routine","pristine"))
    -- print(GetSimilarity(4,"starting","starting"))
    -- print(combMatch(3,"pristine"," routine"))
    -- print(combMatch(3," routine","pristine"))
    function GetDifficulty(word,model,count)
        local scores={}
        for i=1,#AnsWordList do
            local w=AnsWordList[i]
            if between(#w.word,#word/2+.1,#word*2-.1) then
                ins(scores,GetSimilarity(model,word,w.word)*w._srcScore)
            end
        end
        table.sort(scores)
        local sum=0
        for i=#scores-count+1,#scores do
            sum=sum+scores[i]
        end
        return sum/count*100
    end
    -- print(math.floor(GetDifficulty('apt',3,20)))
    -- print(math.floor(GetDifficulty('company',3,20)))
    -- print(math.floor(GetDifficulty('generate',3,20)))
    -- print(math.floor(GetDifficulty('inquiry',3,20)))
    -- print(math.floor(GetDifficulty('themselves',3,20)))
    -- print(math.floor(GetDifficulty('whatsoever',3,20)))
    -- print(math.floor(GetDifficulty('enthusiasm',3,20)))
    -- print(math.floor(GetDifficulty('magnificent',3,20)))
    -- print(math.floor(GetDifficulty('significant',3,20)))
    -- CALCULATE DIFFICULTY OF ALL WORD
    -- for i=1,#WordLib[3] do
    --     local testWord=WordLib[3][i]
    --     if #testWord==8 then
    --         print(testWord,math.floor(GetDifficulty(testWord,3,20)))
    --     end
    -- end
    -- local words={}
    -- for i=1,#AnsWordList do
    --     if #AnsWordList[i].word>12 then
    --         ins(words,AnsWordList[i].word)
    --     end
    -- end
    -- for i=1,#words do
    --     local testWord=words[i]
    --     print(testWord,math.floor(GetDifficulty(testWord,3,20)))
    -- end
end

-- Title
TitleString="Similariddle"
FakeTitleString="Similariddle"
math.randomseed(tonumber(os.date('!%Y%m%d')))
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

-- Saving
GameData={
    date=os.date("!%Y%m%d"),
    dailyPassed=false,
    dailyCount=0,
}
function CheckDate()
    local date=os.date("!%Y%m%d")
    if date>GameData.date then
        GameData.date=date
        GameData.dailyPassed=false
        SaveData()
    end
end
function SaveData()
    print("SaveData")
    pcall(FILE.save,GameData,'save.dat','-luaon')
end
function LoadData()
    print("LoadData")
    local suc,res=pcall(FILE.load,'save.dat','-luaon')
    if suc then TABLE.update(GameData,res) end
end
LoadData()
love.filesystem.remove('guesses.dat')
