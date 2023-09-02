local gc=love.graphics
local ins=table.insert

local scene={}

local inputBox=WIDGET.new{type='inputBox',pos={0,0},x=30,y=20,w=1000-60,h=50,regex='[a-z]'}

local data
local result
local lastGuess
local history,viewHistory
local lastSureTime=-1e99

local function guess(w,giveup)
    if #w==0 then
        MSG.new('info',"Input in a English word then press enter")
        return
    end
    if not WordHashMap[w] then
        MSG.new('info',"Word \""..w.."\" doesn't exist")
        return
    end
    if history[w] then
        lastGuess=history[w]
        -- MSG.new('info',"Already guessed that word!")
        return
    end

    local score,info
    if #w<=#data.word/2 or #w>=#data.word*2 then
        score=-1
        info="X"
    else
        score=MATH.clamp(GetSimilarity(data.model,data.word,w),-1,1)
        info=string.format("%.2f%%",100*score)
        if score==1 then
            if giveup then
                result='gaveup'
                -- TODO: give up
                info="Give Up"
            else
                result='win'
                -- TODO: win
                MSG.new('check',"You got it right!")
            end
        end
    end
    local id=#history+1
    lastGuess={id=id,word=w,score=score,info=info}
    history[id]=lastGuess -- [number]
    history[w]=lastGuess -- [string]
    ins(viewHistory[1],lastGuess)
    ins(viewHistory[2],lastGuess)

    return true
end

function scene.enter()
    data=TABLE.copy(SCN.args[1])
    result=false

    inputBox:setText('')
    history={}
    viewHistory={{},{}}
    lastGuess=nil
end

function scene.resize()
    inputBox.w=SCR.w/SCR.k-60
    inputBox:reset()
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

function scene.draw()
    gc.replaceTransform(SCR.xOy_ul)

    -- Draw words
    FONT.set(30)
    if lastGuess then
        gc.setColor(COLOR.L)
        gc.print(lastGuess.id,45,95)
        gc.print(lastGuess.word,170,95)
        gc.setColor(1-lastGuess.score,1+lastGuess.score,1-math.abs(lastGuess.score))
        gc.print(lastGuess.info,450,95)
    end
end

scene.widgetList={
    inputBox,
    WIDGET.new{type='button_fill',pos={1,1},text='Give up',x=-210,y=-40,w=130,h=70,fontSize=20,code=WIDGET.c_pressKey'='},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-70,y=-40,w=130,h=70,fontSize=30,code=WIDGET.c_pressKey'escape'},
}

return scene
