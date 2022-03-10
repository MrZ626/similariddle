require'Zenitha'

Zenitha.setAppName('similariddle')
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
    local gc=love.graphics

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
    local lastGuess
    local history
    local historyMap
    local scroll=0

    local sortFuncNames={
        'rate_des',
        'rate_asc',
        'id_asc',
        'id_des',
        'word_asc',
    }
    local sortFuncs={
        rate_des=function(a,b)
            return a._score>b._score or a._score==b._score and a.word<b.word
        end,
        rate_asc=function(a,b)
            return a._score<b._score or a._score==b._score and a.word>b.word
        end,
        id_des=function(a,b)
            return a.id>b.id
        end,
        id_asc=function(a,b)
            return a.id<b.id
        end,
        word_asc=function(a,b)
            return a.word<b.word
        end,
    }
    local sortMode

    local function restart()
        answer=questionLib[math.random(#questionLib)]
        inputBox:setText('')
        lastGuess=nil

        history={}
        historyMap={}

        sortMode='rate_des'
        scroll=0
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

    local function guess(w,giveup)
        if #w==0 then
            MES.new('info',"Input in a English word then press enter")
            return
        end
        if not wordHashMap[w] then
            MES.new('info',"Word \""..w.."\" doesn't exist")
            return
        end
        if historyMap[w] then
            MES.new('info',"Already guessed that word!")
            return
        end

        local _score=MATH.interval(getSimilarity(answer,w),-1,1)
        if _score==1 and not giveup then MES.new('info',"You got it right!") end
        lastGuess={
            id=#history+1,
            word=w,
            _score=_score,
            score=giveup and "Give Up" or string.format("%.2f%%",100*_score)
        }
        table.insert(history,lastGuess)
        scroll=0

        table.sort(history,sortFuncs[sortMode])

        historyMap[w]=true
        return true
    end

    function scene.enter()
        restart()
    end

    function scene.wheelMoved(x,y)
        scroll=math.max(0,math.min(scroll-(x+y),#history-15))-- #history-15 may larger than 15, so cannot use MATH.interval
    end

    local floatY=0
    function scene.touchMove(_,_,_,dy)
        floatY=floatY+dy
        if math.abs(floatY)>20 then
            scene.wheelMoved(0,MATH.sign(floatY))
            floatY=floatY-MATH.sign(floatY)*20
        end
    end

    function scene.keyDown(key,isRep)
        if key=='return' then
            if isRep then return end
            local input=inputBox:getText()
            if guess(input) then
                inputBox:setText('')
            end
        elseif key=='tab' then
            sortMode=TABLE.next(sortFuncNames,sortMode)
            table.sort(history,sortFuncs[sortMode])
        elseif key=='=' then
            if isRep then return end
            guess(answer,true)
        elseif key=='escape' then
            if isRep then return end
            if #history==0 then return end
            restart()
        elseif key=='up' then
            scene.wheelMoved(0,1)
        elseif key=='down' then
            scene.wheelMoved(0,-1)
        elseif key=='home' then
            scene.wheelMoved(0,1e99)
        elseif key=='end' then
            scene.wheelMoved(0,-1e99)
        elseif key=='left' or key=='right' then
            -- Do nothing
        else
            WIDGET.focus(inputBox)
            return true
        end
    end

    local function drawWord(w,h)
        gc.setColor(COLOR.L)
        gc.print(w.id,45,95+h*30)
        gc.print(w.word,170,95+h*30)
        gc.setColor(1-w._score,1+w._score,1-math.abs(w._score))
        gc.print(w.score,450,95+h*30)
    end

    function scene.draw()
        -- Dividing line and sorting mode
        gc.setLineWidth(3)
        gc.setColor(COLOR.L)
        gc.line(28,125,900,125)
        FONT.set(15)
        gc.print(sortMode,910,113)

        -- Arrow
        FONT.set(40)
        if history[scroll] then gc.print('↑',7,130) end
        if history[scroll+16] then gc.print('↓',7,530) end

        -- Draw words
        FONT.set(30)
        if lastGuess then
            drawWord(lastGuess,-.5)
        end
        for i=scroll+1,math.min(scroll+15,#history) do
            drawWord(history[i],i-scroll)
        end
    end

    scene.widgetList={
        inputBox,
        WIDGET.new{type='button',pos={1,1},text='Sort',    x=-70, y=-50,w=120,h=80,code=WIDGET.c_pressKey'tab'},
        WIDGET.new{type='button',pos={1,1},text='Give up', x=-200,y=-50,w=120,h=80,code=WIDGET.c_pressKey'='},
        WIDGET.new{type='button',pos={1,1},text='Restart', x=-330,y=-50,w=120,h=80,code=WIDGET.c_pressKey'escape'},
    }

    mainScene=scene
end
SCN.add('main',mainScene)