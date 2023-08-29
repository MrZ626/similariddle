local gc=love.graphics

local scene={}

local inputBox=WIDGET.new{type='inputBox',pos={0,0},x=30,y=20,w=1000-60,h=50,regex='[a-z]'}

local data
local result
local hintStr=""
local lastGuess
local history
local lastSureTime=-1e99

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
        for _=0,1 do -- for swap t1 and t2 then try again
            local n=1
            while true do
                local d=math.floor(n/2)*(-1)^n -- 0,-1,1,-2,2,...
                if d>=len then
                    break
                end
                if t1[i]==t2[i+d] then
                    score=score+Options.matchRateFunc[data.model](len,d)
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
        maxSimilarity=math.max(maxSimilarity,strComp(short,long:sub(i,i+#short-1))-(#long-#short)/#long)
    end
    return maxSimilarity
end

local function guess(w,giveup,auto)
    if #w==0 then
        MSG.new('info',"Input in a English word then press enter")
        return
    end
    if not WordHashMap[w] then
        MSG.new('info',"Word \""..w.."\" doesn't exist")
        return
    end
    if history[w] then
        MSG.new('info',"Already guessed that word!")
        return
    end

    local _score,info
    if #w<=#data.word/2 or #w>=#data.word*2 then
        _score=-1
        info="X"
    else
        _score=MATH.clamp(getSimilarity(data.word,w),-1,1)
        if giveup and _score==1 then
            info="Give Up"
            if #history==0 then
                result='gaveup'
                -- TODO: give up
            end
        else
            info=string.format("%.2f%%",100*_score)
            if _score==1 then
                result='win'
                if not auto then
                    -- TODO: win
                    MSG.new('info',"You got it right!")
                end
            end
        end
    end
    lastGuess={id=#history+1,word=w,_score=_score,info=info}
    table.insert(history,lastGuess)

    return true
end

function scene.enter()
    data=TABLE.copy(SCN.args[1])
    result=false

    inputBox:setText('')
    history={}
    lastGuess=nil
end

function scene.resize()
    inputBox.w=SCR.w/SCR.k-60
    inputBox:reset()
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
    elseif key=='=' then
        if isRep then return end
        if result then return end
        if love.timer.getTime()-lastSureTime<1 then
            guess(data.word,true)
        else
            MSG.new('warn','Press again to give up')
        end
        lastSureTime=love.timer.getTime()
    elseif key=='c' and love.keyboard.isDown('lctrl','rctrl') then
        if data.fixed then
            MSG.new('info',"Can't export code in this mode")
            return
        else
            -- print("word: "..data.word)
            -- print("lib: "..data.lib)
            -- print("len: "..data.len)
            -- print("model: "..data.model)
            local id=TABLE.find(WordLib[data.lib],data.word)
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
            love.system.setClipboardText(string.format("%x",p))
            MSG.new('check',"Riddle code copied to clipboard!")
        end
    elseif key=='escape' then
        if isRep then return end
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",1)
        else
            SCN.back()
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

    -- Dividing line and sorting mode
    gc.setLineWidth(3)
    gc.line(28,125,SCR.w/SCR.k-100,125)
    FONT.set(15)
    gc.printf(hintStr,SCR.w/SCR.k-626,140,600,'right')

    -- Draw words
    FONT.set(30)
    if lastGuess then
        drawWord(lastGuess,-.5)
    end
end

scene.widgetList={
    inputBox,
    WIDGET.new{type='button',pos={1,1},text='Give up',x=-180,y=-50,w=150,h=80,code=WIDGET.c_pressKey'='},
}

return scene
