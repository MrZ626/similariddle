require'Zenitha'

Zenitha.setAppName('similariddle')
Zenitha.setVersionText(require"version".appVer)
Zenitha.setFirstScene('main')
Zenitha.setMaxFPS(60)-- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)

love.keyboard.setKeyRepeat(true)
if love.system.getOS()=='Android'or love.system.getOS()=='iOS' then
    love.window.setFullscreen(true)
end

SCR.setSize(1000,600)

FONT.load{
    main='proportional.otf',
}
FONT.setDefaultFont('main')

local mainScene do
    local gc=love.graphics

    local scene={}

    local inputBox=WIDGET.new{type='inputBox',pos={0,0},x=30,y=20,w=1000-60,h=50,regex='[a-z]'}

    local wordHashMap={}

    local questionLib=STRING.split(FILE.load('question_lib.txt'),'\r\n')
    for i=1,#questionLib do wordHashMap[questionLib[i]]=true end

    local _superWordLib=STRING.split(FILE.load('word_lib.txt'),'\r\n')
    for i=1,#_superWordLib do wordHashMap[_superWordLib[i]]=true end
    _superWordLib=nil
    collectgarbage()

    local dailyWord
    local answer
    local lastGuess
    local history
    local historyMap
    local rawHistory
    local scroll=0
    local records={'一','一','一','一','一'}
    local recordStr="Records: 一  一  一  一  一"
    local lastSureTime=-1e99

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

    local function saveState()
        FILE.save({
            answer=answer,
            hisList=rawHistory,
            records=records,
            sortMode=sortMode,
        },'guesses.dat','-luaon -expand')
    end

    local function freshRecordStr()
        recordStr="Records: "..table.concat(records,"  ")
    end

    local function restart()
        answer=questionLib[math.random(#questionLib)]
        inputBox:setText('')
        scene.widgetList[5]._visible=true
        lastGuess=nil

        history={}
        historyMap={}
        rawHistory={}

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

        scene.widgetList[5]._visible=false

        local _score,result
        if #w<=#answer/2 or #w>=#answer*2 then
            _score=-1
            result="X"
        else
            _score=MATH.interval(getSimilarity(answer,w),-1,1)
            if giveup then
                result="Give Up"
                table.insert(records,"X")
            else
                result=string.format("%.2f%%",100*_score)
                if _score==1 then
                    if answer==dailyWord then
                        MES.new('info',"Daily puzzle solved!")
                    else
                        table.insert(records,#history+1)
                        MES.new('info',"You got it right!")
                    end
                end
            end
            if #records>5 then table.remove(records,1) end
            freshRecordStr()
        end
        lastGuess={
            id=#history+1,
            word=w,
            _score=_score,
            result=result
        }
        table.insert(history,lastGuess)
        table.insert(rawHistory,w)
        scroll=0

        table.sort(history,sortFuncs[sortMode])

        historyMap[w]=true
        saveState()
        return true
    end

    local function loadState()
        if love.filesystem.getInfo('guesses.dat') then
            local data=FILE.load('guesses.dat','-luaon')

            answer=data.answer
            for i=1,#data.hisList do
                guess(data.hisList[i],data.hisList[i]==answer)
            end
            records=data.records
            freshRecordStr()

            sortMode=data.sortMode
            table.sort(history,sortFuncs[sortMode])
        end
    end

    function scene.enter()
        math.randomseed(os.date'%Y'*1000+os.date'%m'*100+os.date'%d')
        dailyWord=questionLib[math.random(#questionLib)]
        math.randomseed(love.timer.getTime())

        restart()
        local res,info=pcall(loadState)
        if not res then
            MES.new('error',info)
            restart()
        end
    end

    function scene.resize()
        inputBox.w=SCR.w/SCR.k-60
        inputBox:reset()
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
            if love.timer.getTime()-lastSureTime<1 then
                guess(answer,true)
            else
                MES.new('warn','Press again to give up')
            end
            lastSureTime=love.timer.getTime()
        elseif key=='escape' then
            if isRep then return end
            if #history==0 then return end
            if love.timer.getTime()-lastSureTime<1 then
                restart()
                table.insert(records,"X")
                if #records>5 then table.remove(records,1) end
                freshRecordStr()
                saveState()
            else
                MES.new('warn','Press again to restart')
            end
            lastSureTime=love.timer.getTime()
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
        elseif key=='-' then
            if #history==0 then
                answer=dailyWord
                scene.widgetList[5]._visible=false
                MES.new('info',"Daily puzzle doesn't effect records")
            end
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
        gc.print(w.result,450,95+h*30)
    end

    function scene.draw()
        gc.replaceTransform(SCR.xOy_ul)

        -- Arrow
        FONT.set(40)
        gc.setColor(COLOR.L)
        if history[scroll] then gc.print('↑',7,130) end
        if history[scroll+16] then gc.print('↓',7,530) end

        -- Draw records
        if records[1] then
            FONT.set(20)
            gc.printf(recordStr,SCR.w/SCR.k-1100,85,1000,'right')
        end

        -- Dividing line and sorting mode
        gc.setLineWidth(3)
        if answer==dailyWord then gc.setColor(COLOR.lY) end
        gc.line(28,125,SCR.w/SCR.k-100,125)
        FONT.set(15)
        gc.print(sortMode,SCR.w/SCR.k-90,113)

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
        WIDGET.new{type='button',pos={1,1},text='Daily',   x=-460,y=-50,w=120,h=80,code=WIDGET.c_pressKey'-'},
    }

    mainScene=scene
end
SCN.add('main',mainScene)