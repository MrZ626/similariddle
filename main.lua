require'Zenitha'

Zenitha.setAppName('similariddle')
Zenitha.setVersionText(require"version".appVer)
Zenitha.setFirstScene('main')
Zenitha.setMaxFPS(40)-- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)
Zenitha.setOnFnKeys({NULL,NULL,NULL,NULL,NULL,NULL,love._openConsole})

love.keyboard.setKeyRepeat(true)
if MOBILE then
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

    local questionLib=STRING.split(FILE.load('question_lib.txt','-string'),'\r\n')
    for i=1,#questionLib do wordHashMap[questionLib[i]]=true end

    local superWordLib=STRING.split(FILE.load('word_lib.txt','-string'),'\r\n')
    for i=1,#superWordLib do wordHashMap[superWordLib[i]]=true end
    superWordLib=nil
    collectgarbage()

    local dailyWord,answer,result
    local hintStr=""
    local lastGuess
    local history,rawHistory,historyMap
    local scroll=0
    local records={'-','-','-','-','-'}
    local recordStr="Records: -  -  -  -  -"
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
            result=result,
            hisList=rawHistory,
            records=records,
            sortMode=sortMode,
        },'guesses.dat','-luaon -expand')
    end

    local function freshRecord(res)
        if res then table.insert(records,res) end
        if #records>5 then table.remove(records,1) end
        recordStr="Records: "..table.concat(records,"  ")
    end

    local function strComp(s1,s2)
        assert(#s1==#s2,"strComp(s1,s2): #s1!=#s2")
        local len=#s1
        local t1,t2={},{}
        for i=1,len do
            t1[i]=s1:sub(i,i)
            t2[i]=s2:sub(i,i)
        end
        local score=0
        for i=1,len do
            for _=0,1 do-- for swap t1 and t2 then try again
                local n=1
                while true do
                    local d=math.floor(n/2)*(-1)^n-- 0, -1, 1, -2, 2, ...
                    if d>=len then break end
                    if t1[i]==t2[i+d] then
                        score=score+1/(math.abs(d)+1)-- Arithmetic typewriter
                        -- score=score+1-math.abs(d)/len/2-- Graceful failure
                        -- score=score+math.max(1-math.abs(d)/3,0)-- Trisected principle
                        -- ? -- stable maintenance
                        break
                    end
                    n=n+1
                end
                t1,t2=t2,t1
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

    local function newWord(w)
        if w then
            answer=w
        else
            repeat
                answer=questionLib[math.random(#questionLib)]
            until answer~=dailyWord
        end

        local rateRank={}
        for i=1,#questionLib do
            rateRank[i]=getSimilarity(answer,questionLib[i])
        end
        table.sort(rateRank)

        hintStr=string.format("100th: %.2f%%\n26th: %.2f%%",100*rateRank[#rateRank-99],100*rateRank[#rateRank-25])
    end

    local function restart()
        newWord()
        inputBox:setText('')
        scene.widgetList[4]._visible=false
        scene.widgetList[5]._visible=true
        lastGuess=nil

        result=false
        history={}
        historyMap={}
        rawHistory={}

        sortMode='rate_des'
        scroll=0
    end

    local function guess(w,giveup,auto)
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

        if #history==0 then
            scene.widgetList[4]._visible=true
            scene.widgetList[5]._visible=false
        end

        local _score,info
        if #w<=#answer/2 or #w>=#answer*2 then
            _score=-1
            info="X"
        else
            _score=MATH.clamp(getSimilarity(answer,w),-1,1)
            if giveup and _score==1 then
                info="Give Up"
                if answer~=dailyWord or #history==0 then
                    result='gaveup'
                    if not auto and #history>0 then
                        freshRecord("X")
                    end
                end
            else
                info=string.format("%.2f%%",100*_score)
                if _score==1 then
                    result='win'
                    if answer==dailyWord then
                        MES.new('info',"Daily puzzle solved!")
                    else
                        if not auto then
                            freshRecord(#history+1)
                            MES.new('info',"You got it right!")
                        end
                    end
                end
            end
        end
        lastGuess={
            id=#history+1,
            word=w,
            _score=_score,
            info=info
        }
        table.insert(history,lastGuess)
        table.insert(rawHistory,w)
        scroll=0

        historyMap[w]=true

        if not auto then
            table.sort(history,sortFuncs[sortMode])
            saveState()
        end
        return true
    end

    local function loadState()
        if love.filesystem.getInfo('guesses.dat') then
            local data=FILE.load('guesses.dat','-luaon')

            newWord(data['answer'])
            result=data['result']
            for i=1,#data['hisList'] do
                guess(data['hisList'][i],result=='gaveup',true)
            end
            records=data['records']
            freshRecord()

            sortMode=data['sortMode']
            table.sort(history,sortFuncs[sortMode])
        end
    end

    function scene.enter()
        local r=love.math.newRandomGenerator()
        r:setSeed(os.date'%Y'*1000+os.date'%m'*100+os.date'%d')
        dailyWord=questionLib[r:random(#questionLib)]
        math.randomseed(math.floor(love.timer.getTime()))

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
        scroll=math.max(0,math.min(scroll-(x+y),#history-15))-- #history-15 may larger than 15, so cannot use MATH.clamp
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
            if result then return end
            if answer==dailyWord then
                MES.new('info','Never gonna give~you~up')
            else
                if love.timer.getTime()-lastSureTime<1 then
                    guess(answer,true)
                else
                    MES.new('warn','Press again to give up')
                end
                lastSureTime=love.timer.getTime()
            end
        elseif key=='escape' then
            if isRep then return end
            if answer==dailyWord then
                if #history==0 then
                    restart()
                    saveState()
                elseif love.timer.getTime()-lastSureTime<1 then
                    restart()
                    saveState()
                else
                    lastSureTime=love.timer.getTime()
                    MES.new('warn','Press again to restart')
                end
            elseif #history~=0 then
                if love.timer.getTime()-lastSureTime<1 then
                    if not result then
                        freshRecord("X")
                    end
                    restart()
                    saveState()
                else
                    lastSureTime=love.timer.getTime()
                    MES.new('warn','Press again to restart')
                end
            end
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
                newWord(dailyWord)
                scene.widgetList[4]._visible=true
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
        gc.print(w.info,450,95+h*30)
    end

    function scene.draw()
        gc.replaceTransform(SCR.xOy_ul)

        -- Arrow
        FONT.set(40)
        gc.setColor(COLOR.L)
        if history[scroll] then gc.print('↑',7,130) end
        if history[scroll+16] then gc.print('↓',7,530) end

        -- Draw records
        if answer~=dailyWord then
            FONT.set(20)
            gc.printf(recordStr,SCR.w/SCR.k-1100,85,1000,'right')
        end

        -- Dividing line and sorting mode
        gc.setLineWidth(3)
        if answer==dailyWord then gc.setColor(COLOR.lY) end
        gc.line(28,125,SCR.w/SCR.k-100,125)
        FONT.set(15)
        gc.print(sortMode,SCR.w/SCR.k-90,113)
        gc.printf(hintStr,SCR.w/SCR.k-626,140,600,'right')

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
        WIDGET.new{type='button',pos={1,1},text='Sort',             x=-70, y=-50,w=120,h=80,code=WIDGET.c_pressKey'tab'},
        WIDGET.new{type='button',pos={1,1},text='Give up',          x=-200,y=-50,w=120,h=80,code=WIDGET.c_pressKey'='},
        WIDGET.new{type='button',pos={1,1},text='Restart',          x=-330,y=-50,w=120,h=80,code=WIDGET.c_pressKey'escape'},
        WIDGET.new{type='button',pos={1,1},text='Daily',color='lY', x=-330,y=-50,w=120,h=80,code=WIDGET.c_pressKey'-'},
    }

    mainScene=scene
end
SCN.add('main',mainScene)
