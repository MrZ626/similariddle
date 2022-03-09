require'Zenitha'

Zenitha.setAppName('similaridle')
Zenitha.setVersionText('V0.1')
Zenitha.setFirstScene('main')
Zenitha.setMaxFPS(30)-- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)

SCR.setSize(1000,600)

FONT.load{
    main='proportional.otf',
}
FONT.setDefaultFont('main')

local mainScene do
    local scene={}

    local wordHashMap={}

    local questionLib=STRING.split(FILE.load('question_lib.txt'),'\r\n')
    for i=1,#questionLib do wordHashMap[questionLib[i]]=true end

    local _superWordLib=STRING.split(FILE.load('word_lib.txt'),'\r\n')
    for i=1,#_superWordLib do wordHashMap[_superWordLib[i]]=true end
    _superWordLib=nil
    collectgarbage()

    local answer
    local input
    local history
    local historyMap

    local function strComp(w1,w2)
        assert(#w1==#w2,"function strComp(w1,w2): #w1 must be equal to #w2")
        local len=#w1
        local t1,t2={},{}
        for i=1,len do
            t1[i]=w1:sub(i,i)
            t2[i]=w2:sub(i,i)
        end
        local score=0
        for i=1,len do
            local n=1
            while true do
                local d=math.floor(n/2)*(-1)^n
                if d>len then break end
                if t1[i]==t2[i+d] then
                    score=score+1/(math.abs(d)+1)
                    break
                end
                n=n+1
            end

            n=1
            while true do
                local d=math.floor(n/2)*(-1)^n
                if d>len then break end
                if t2[i]==t1[i+d] then
                    score=score+1/(math.abs(d)+1)
                    break
                end
                n=n+1
            end
        end
        return score/len/2
    end

    local function getSimilarity(w1,w2)
        local maxSimilarity=-1e99
        local short,long=#w1<#w2 and w1 or w2,#w1<#w2 and w2 or w1

        for i=1,#long-#short+1 do
            maxSimilarity=math.max(maxSimilarity,
                strComp(short,long:sub(i,i+#short-1))
                -(#long-#short)/#long
            )
        end
        return maxSimilarity
    end

    local function restart()
        answer=questionLib[math.random(#questionLib)]
        input=""
        history={}
        historyMap={}
    end

    function scene.enter()
        restart()
    end

    function scene.keyDown(key,isRep)
        if isRep then return end
        if key:match('^%a$') then
            input=input..key
        elseif key=='backspace' then
            input=input:sub(1,-2)
        elseif key=='return' then
            if #input>0 then
                if not wordHashMap[input] then
                    MES.new('info',"Word \""..input.."\" doesn't exist")
                    return
                end
                if historyMap[input] then
                    MES.new('info',"You already guessed that word!")
                    return
                end

                local _score=MATH.interval(getSimilarity(answer,input),-1,1)
                if _score==1 then MES.new('info',"You got it right! --Copilot") end
                table.insert(history,{
                    id=#history+1,
                    word=input,
                    _score=_score,
                    score=string.format("%.2f%%",100*_score)
                })

                historyMap[input]=true
                input=''
            end
        elseif key=='tab' then
            input=answer
        elseif key=='escape' then
            restart()
        end
    end

    function scene.draw()
        FONT.set(30)
        love.graphics.setColor(1,1,1)
        love.graphics.print('> '..input,30,20)
        for i=1,#history do
            local h=history[i]
            love.graphics.setColor(1,1,1)
            love.graphics.print(h.id,30,50+i*30)
            love.graphics.print(h.word,100,50+i*30)
            love.graphics.setColor(1-h._score,1+h._score,1-math.abs(h._score))
            love.graphics.print(h.score,400,50+i*30)
        end
    end

    mainScene=scene
end
SCN.add('main',mainScene)