require'Zenitha'

Zenitha.setAppName('similaridle')
Zenitha.setVersionText('V0.1')
Zenitha.setFirstScene('main')
Zenitha.setMaxFPS(30)-- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)

love.keyboard.setKeyRepeat(true)

SCR.setSize(1000,600)

FONT.load{
    main='proportional.otf',
}
FONT.setDefaultFont('main')

local mainScene do
    local scene={}

    local inputBox=WIDGET.new{type='inputBox',x=30,y=20,w=1000-60,h=50,regex='[a-z]'}

    local wordHashMap={}

    local questionLib=STRING.split(FILE.load('question_lib.txt'),'\r\n')
    for i=1,#questionLib do wordHashMap[questionLib[i]]=true end

    local _superWordLib=STRING.split(FILE.load('word_lib.txt'),'\r\n')
    for i=1,#_superWordLib do wordHashMap[_superWordLib[i]]=true end
    _superWordLib=nil
    collectgarbage()

    local answer
    local history
    local historyMap

    local sortFuncNames={
        'rate_asc',
        'rate_des',
        'id_asc',
        'id_des',
        'word_asc',
    }
    local sortFuncs={
        rate_asc=function(a,b)
            return a._score>b._score or a._score==b._score and a.word<b.word
        end,
        rate_des=function(a,b)
            return a._score<b._score or a._score==b._score and a.word>b.word
        end,
        id_asc=function(a,b)
            return a.id<b.id
        end,
        id_des=function(a,b)
            return a.id>b.id
        end,
        word_asc=function(a,b)
            return a.word<b.word
        end,
    }
    local sortMode

    local function restart()
        answer=questionLib[math.random(#questionLib)]
        inputBox:setText('')
        history={}
        historyMap={}
        sortMode='rate_asc'
    end

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

    local function guess(w)
        local _score=MATH.interval(getSimilarity(answer,w),-1,1)
        if _score==1 then MES.new('info',"You got it right!") end
        table.insert(history,{
            id=#history+1,
            word=w,
            _score=_score,
            score=string.format("%.2f%%",100*_score)
        })

        table.sort(history,sortFuncs[sortMode])

        historyMap[w]=true
    end

    function scene.enter()
        restart()
    end

    function scene.keyDown(key,isRep)
        if key=='return' then
            if isRep then return end
            local input=inputBox:getText()
            if #input==0 then
                MES.new('info',"Input in a English word then press enter")
                return
            end
            if not wordHashMap[input] then
                MES.new('info',"Word \""..input.."\" doesn't exist")
                return
            end
            if historyMap[input] then
                MES.new('info',"You already guessed that word!")
                return
            end

            guess(input)

            inputBox:setText('')
        elseif key=='tab' then
            sortMode=TABLE.next(sortFuncNames,sortMode)
            table.sort(history,sortFuncs[sortMode])
        elseif key=='=' then
            if isRep then return end
            if love.keyboard.isDown('lctrl','rctrl') then
                inputBox:setText(answer)
            end
        elseif key=='_ANS' then
            inputBox:setText(answer)
        elseif key=='escape' then
            if isRep then return end
            if #history==0 then return end
            restart()
        else
            WIDGET.focus(inputBox)
            return true
        end
    end

    local function drawWord(w,h)
        love.graphics.setColor(COLOR.L)
        love.graphics.print(w.id,30,95+h*30)
        love.graphics.print(w.word,150,95+h*30)
        love.graphics.setColor(1-w._score,1+w._score,1-math.abs(w._score))
        love.graphics.print(w.score,450,95+h*30)
    end

    function scene.draw()
        -- Dividing line
        love.graphics.setLineWidth(3)
        love.graphics.setColor(COLOR.L)
        love.graphics.line(28,125,900,125)

        FONT.set(15)
        love.graphics.print(sortMode,910,113)

        --Draw words
        FONT.set(30)
        for i=1,#history do
            if history.id==#history then
                drawWord(history[i],-.5)
            end
            drawWord(history[i],i)
        end
    end

    scene.widgetList={
        inputBox,
        WIDGET.new{type='button',pos={1,1},text='give up',  x=-50,y=-50,w=80,h=80,code=WIDGET.c_pressKey'_ANS'},
        WIDGET.new{type='button',pos={1,1},text='Sort',     x=-140,y=-50,w=80,h=80,code=WIDGET.c_pressKey'tab'},
        WIDGET.new{type='button',pos={1,1},text='Restart',  x=-230,y=-50,w=80,h=80,code=WIDGET.c_pressKey'escape'},
    }

    mainScene=scene
end
SCN.add('main',mainScene)