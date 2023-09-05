--- @class guess
--- @field id number
--- @field word string
--- @field score number
--- @field info string
--- @field color Zenitha.Color
--- @field idFont number
--- @field textObj love.Text

local gc=love.graphics
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_line=gc.draw,gc.line
local gc_rectangle,gc_circle=gc.rectangle,gc.circle
local gc_print,gc_printf=gc.print,gc.printf
local getFont,setFont=FONT.get,FONT.set

local ins=table.insert

local scene={}

local wordW,wordH
--- @param item guess
local function listDrawFunc(item)
    gc_setColor(item.color)
    gc_rectangle('fill',3,3,wordW-6,wordH-6)
    gc_setColor(COLOR.L)
    setFont(item.idFont)
    gc_print(item.id,6,3)
    if item.rank then
        setFont(10)
        gc_print(item.rank,6,21)
    end

    local l=#item.word
    local t=item.textObj
    local k=math.log(l,2.6)/l*3
    local anchorY=t:getHeight()*.47
    gc_draw(t,30,wordH/2,nil,k,nil,0,anchorY)
    gc_draw(t,30.5,wordH/2,nil,k,nil,0,anchorY)

    setFont(20)
    gc_printf(item.info,0,8,wordW-5,'right')
end

--- @type Zenitha.widget.inputBox
local inputBox=WIDGET.new{type='inputBox',pos={0,0},regex='[a-z]',lineWidth=2}
--- @type Zenitha.widget.listBox
local hisBox1=WIDGET.new{type='listBox',pos={0,0},drawFunc=listDrawFunc,lineHeight=35,lineWidth=2}
--- @type Zenitha.widget.listBox
local hisBox2=WIDGET.new{type='listBox',pos={0,0},drawFunc=listDrawFunc,lineHeight=35,lineWidth=2}

--- @type table current game's params (word & settings)
local data
--- @type table<string,number>
local wordRankHashtable={}
--- @type string|boolean
local result
--- @type guess?
local lastGuess
--- @type table<number|string,guess>
local history
--- @type table<table<guess>>
local viewHistory

local function guess(w,giveup)
    if #w==0 then
        MSG.new('info',"Input in a English word then press enter",0.5)
        return
    end
    if not WordHashMap[w] then
        MSG.new('info',"Word \""..w.."\" doesn't exist",0.5)
        return
    end
    if history[w] then
        lastGuess=history[w]
        -- MSG.new('info',"Already guessed that word!",0.5)
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
                MSG.new('check',"You got it right!",2.6)
            end
        end
    end
    local id=#history+1
    lastGuess={
        id=id,word=w,score=score,
        info=info,
        color={1-score,1+score,1-math.abs(score),.26},
        rank=wordRankHashtable[w] and (wordRankHashtable[w]<1000 and wordRankHashtable[w] or math.floor(wordRankHashtable[w]/1000).."k"),
        idFont=id<100 and 15 or id<1000 and 10 or 7,
        textObj=gc.newText(getFont(25),w),
    }
    history[id]=lastGuess -- [number]
    history[w]=lastGuess -- [string]
    ins(viewHistory[1],lastGuess)
    ins(viewHistory[2],lastGuess)

    return true
end

function scene.enter()
    data=TABLE.copy(SCN.args[1])
    -- for k,v in next,data do print(k,v)end
    result=false

    history={}
    viewHistory={{},{}}
    lastGuess=nil

    local model,word=data.model,data.word
    local clamp=MATH.clamp
    for i=1,#AnswerWordList do
        local w=AnswerWordList[i]
        w[2]=clamp(GetSimilarity(model,word,w[1]),-1,1)
    end
    table.sort(AnswerWordList,function(a,b) return a[2]>b[2] end)
    local prev={"MrZ",26}
    for i=1,#AnswerWordList do
        local cur=AnswerWordList[i]
        wordRankHashtable[cur[1]]=cur[2]==prev[2] and wordRankHashtable[prev[1]] or i
        prev=cur
    end
    collectgarbage()
    for i=1,100 do print(AnswerWordList[i][1],AnswerWordList[i][2]) end

    inputBox:setText('')
    hisBox1:setList(viewHistory[1])
    hisBox2:setList(viewHistory[2])
    scene.resize()

    MSG.setSafeY(70)
end
function scene.leave()
    MSG.setSafeY(0)
end

function scene.resize()
    local fullWidth=SCR.w/SCR.k
    local fullHeight=SCR.h/SCR.k

    local hisX,hisY=0,120
    local hisW,hisH=fullWidth*0.7,fullHeight-120
    local gap=15
    -- hisBox's size: 270~400, 35
    wordW,wordH=hisW/2-gap*1.5,35

    inputBox.x,inputBox.y,inputBox.w,inputBox.h=gap*0.9,gap*0.9,fullWidth-0.9*2*gap,50
    hisBox1.x,hisBox1.y,hisBox1.w,hisBox1.h=hisX+gap,hisY+gap,wordW,hisH-2*gap
    hisBox2.x,hisBox2.y,hisBox2.w,hisBox2.h=hisX+gap+hisW/2,hisY+gap,wordW,hisH-2*gap


    inputBox:reset()
    hisBox1:reset()
    hisBox2:reset()
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
        if TASK.lock("sureGiveup",1) then
            MSG.new('warn','Press again to give up',0.5)
        else
            guess(data.word,true)
        end
    elseif key=='c' and love.keyboard.isDown('lctrl','rctrl') then
        if data.fixed then
            MSG.new('info',"Can't export code in this mode",0.5)
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
            MSG.new('check',"Riddle code copied to clipboard!",1)
        end
    elseif key=='v' and love.keyboard.isDown('lctrl','rctrl') then
        local text=love.system.getClipboardText()
        if not text then return end
        inputBox:setText(text:readLine():trim():gsub('[^a-z]',''))
    elseif key=='escape' then
        if isRep then return end
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",0.5)
        else
            SCN.back()
        end
    elseif key=='up' then
        -- scene.wheelMoved(0,1)
    elseif key=='down' then
        -- scene.wheelMoved(0,-1)
    elseif key=='home' then
        -- scene.wheelMoved(0,1e99)
    elseif key=='end' then
        -- scene.wheelMoved(0,-1e99)
    elseif key=='left' or key=='right' then
        -- Do nothing
    else
        if not WIDGET.isFocus(inputBox) then
            WIDGET.focus(inputBox)
            if #key==1 and key:match('[a-z]') then
                inputBox:addText(key)
            end
        end
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
    inputBox,hisBox1,
    -- hisBox2,
    WIDGET.new{type='button_fill',pos={1,1},text='Give up',x=-225,y=-50,w=130,h=70,fontSize=20,code=WIDGET.c_pressKey'='},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,fontSize=30,code=WIDGET.c_pressKey'escape'},
}

return scene
