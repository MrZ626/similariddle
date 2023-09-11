--- @class guess
--- @field id number
--- @field word string
--- @field length number
--- @field score number
--- @field info string
--- @field rank string|number
--- @field textObj love.Text
--- @field bgColor Zenitha.Color
--- @field rankColor Zenitha.Color
--- @field idFont number
--- @field wordLight string
--- @field textObjLight love.Text

local GC=GC
local gc=love.graphics
local gc_replaceTransform,gc_translate=gc.replaceTransform,gc.translate
local gc_setColor,gc_setLineWidth=gc.setColor,gc.setLineWidth
local gc_draw,gc_rectangle,gc_circle=gc.draw,gc.rectangle,gc.circle
local gc_print,gc_printf=gc.print,gc.printf
local getFont,setFont=FONT.get,FONT.set
local ins=table.insert
local find,sub,rep,paste=string.find,string.sub,string.rep,STRING.paste

local methodName={"score","id","word","length"}
local dirName={"ascend","descend"}

local defaultSortMethod={
    {
        {"score","descend"},
        {"word","ascend"},
    },
    {
        {"id","descend"},
        {"word","ascend"},
    }
}

local wordW,wordH
local side=3
--- @param item guess
local function listDrawFunc(item)
    gc_setColor(item.bgColor)
    gc_rectangle('fill',side,side,wordW-side*2,wordH-side*2)
    gc_setColor(COLOR.L)
    setFont(item.idFont)
    gc_print(item.id,6,3)
    if item.rank then
        setFont(10)
        gc_setColor(item.rankColor)
        gc_print(item.rank,6,21)
    end

    local t1,t2=item.textObj,item.textObjLight
    local l=#item.word
    local k=math.log(l,2.6)/l*3
    local anchorY=t1:getHeight()*.47
    gc_setColor(COLOR.L)
    gc_draw(t1,30,wordH/2,nil,k,nil,0,anchorY)
    gc_draw(t1,30.5,wordH/2,nil,k,nil,0,anchorY)
    gc_setColor(COLOR.Y)
    gc_draw(t2,30,wordH/2,nil,k,nil,0,anchorY)
    gc_draw(t2,30.5,wordH/2,nil,k,nil,0,anchorY)

    setFont(20)
    gc_setColor(COLOR.L)
    gc_printf(item.info,0,8,wordW-5,'right')
end

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
local viewHistory={}

local hisSortMethods={}
local hisViewCount=2
local lastInput

local hisSortMethod
local function hisSortFunc(g1,g2)
    for j=1,#hisSortMethod do
        local v1,v2=g1[hisSortMethod[j][1]],g2[hisSortMethod[j][1]]
        if v1~=v2 then
            return v1<v2==(hisSortMethod[j][2]=="ascend")==(hisSortMethod[j][1]=="score")
        end
    end
    return true
end
--- @param guess? guess
--- @param id? number
local function updateViewHis(guess,id)
    for i=1,hisViewCount do
        if not id or i==id then
            if guess then ins(viewHistory[i],guess) end
            hisSortMethod=hisSortMethods[i]
            table.sort(viewHistory[i],hisSortFunc)
        end
    end
end

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
        return true
    end

    local score,info
    if #w<=#data.word/2 or #w>=#data.word*2 then
        score=-26
        info="X"
    else
        score=GetSimilarity(data.model,data.word,w)
        info=string.format("%.2f%%",100*score)
        if w==data.word then
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
    local rank,rankColor
    if wordRankHashtable[w] then
        rank=wordRankHashtable[w]<1000 and wordRankHashtable[w] or math.floor(wordRankHashtable[w]/1000).."k"
        rankColor=COLOR.L
    else
        local l,r=1,#AnswerWordList
        while l<r do
            local m=math.floor((l+r)/2)
            if score<AnswerWordList[m][2] then
                l=m+1
            else
                r=m
            end
        end
        rank=l<1000 and l or math.floor(l/1000).."k"
        rankColor=COLOR.LD
    end
    lastGuess={
        id=id,
        word=w,
        length=#w,
        score=score,
        info=info,
        rank=rank,
        textObj=gc.newText(getFont(25),w),
        bgColor={1-score,1+score,1-math.abs(score),.26},
        rankColor=rankColor,
        idFont=id<100 and 15 or id<1000 and 10 or 7,
        wordLight="",
        textObjLight=gc.newText(getFont(25),""),
    }
    history[id]=lastGuess -- [number]
    history[w]=lastGuess -- [string]
    updateViewHis(lastGuess,nil)

    return true
end

--- @type Zenitha.widget.inputBox
local inputBox=WIDGET.new{type='inputBox',pos={0,0},regex='[a-z]',maxInputLength=41,lineWidth=2}
--- @type Zenitha.widget.listBox,Zenitha.widget.listBox
local hisBox1,hisBox2=
    WIDGET.new{type='listBox',pos={0,0},drawFunc=listDrawFunc,lineHeight=35,lineWidth=2,scrollBarWidth=4,scrollBarPos='right'},
    WIDGET.new{type='listBox',pos={0,0},drawFunc=listDrawFunc,lineHeight=35,lineWidth=2,scrollBarWidth=4,scrollBarPos='right'}

local hisType1,hisDir1,hisType2,hisDir2
local function setSortTitle(i,mode)
    hisSortMethods[i][1][1]=mode
    local btn=i==1 and hisType1 or hisType2
    btn.text=hisSortMethods[i][1][1]
    updateViewHis(nil,i)
    btn:reset()
end
local function setSortDir(i,mode)
    hisSortMethods[i][1][2]=mode
    local btn=i==1 and hisDir1 or hisDir2
    btn.text=hisSortMethods[i][1][2]=="ascend" and "↑" or "↓"
    updateViewHis(nil,i)
    btn:reset()
end
--- @type Zenitha.widget.button
hisType1=WIDGET.new{type='button',pos={0,0},fontSize=25,code=function() setSortTitle(1,TABLE.next(methodName,hisSortMethods[1][1][1])) end,lineWidth=2}
--- @type Zenitha.widget.button
hisDir1=WIDGET.new{type='button',pos={0,0},code=function() setSortDir(1,TABLE.next(dirName,hisSortMethods[1][1][2])) end,lineWidth=2}
--- @type Zenitha.widget.button
hisType2=WIDGET.new{type='button',pos={0,0},fontSize=25,code=function() setSortTitle(2,TABLE.next(methodName,hisSortMethods[2][1][1])) end,lineWidth=2}
--- @type Zenitha.widget.button
hisDir2=WIDGET.new{type='button',pos={0,0},code=function() setSortDir(2,TABLE.next(dirName,hisSortMethods[2][1][2])) end,lineWidth=2}

local scene={}

function scene.enter()
    data=TABLE.copy(SCN.args[1])
    -- data.word='significant'
    -- for k,v in next,data do print(k,v)end

    result=false
    lastGuess=nil
    history={}
    for i=1,hisViewCount do
        viewHistory[i]={}
        hisSortMethods[i]=TABLE.shift(defaultSortMethod[i])
    end
    lastInput=""

    local model,word=data.model,data.word
    for i=1,#AnswerWordList do
        local w=AnswerWordList[i]
        w[2]=GetSimilarity(model,word,w[1])
    end
    table.sort(AnswerWordList,function(a,b) return a[2]>b[2] end)
    local prev={"MrZ",26}
    for i=1,#AnswerWordList do
        local cur=AnswerWordList[i]
        wordRankHashtable[cur[1]]=cur[2]==prev[2] and wordRankHashtable[prev[1]] or i
        prev=cur
    end
    collectgarbage()
    -- for i=1,100 do print(AnswerWordList[i][1],AnswerWordList[i][2]) end

    setSortTitle(1,"score")
    setSortDir(1,"descend")
    setSortTitle(2,"id")
    setSortDir(2,"descend")
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
    local hisBtnH=50
    local hisW,hisH=fullWidth*0.7,fullHeight-120-hisBtnH
    local gap=15
    -- hisBox's size: 270~400, 35
    wordW,wordH=hisW/2-gap*1.5,35

    inputBox.x,inputBox.y,inputBox.w,inputBox.h=gap*1.2,gap*0.9+5,fullWidth-1.2*2*gap,40
    hisBox1.x,hisBox1.y,hisBox1.w,hisBox1.h=hisX+gap,hisY+gap,wordW,hisH-2*gap
    hisBox2.x,hisBox2.y,hisBox2.w,hisBox2.h=hisX+gap+hisW/2,hisY+gap,wordW,hisH-2*gap
    hisType1.x,hisType1.y,hisType1.w,hisType1.h=
        (hisX+gap+wordW)/2-(hisW/6+hisBtnH+gap/2)/2+hisW/6/2,
        hisY+hisH+hisBtnH/2-gap/2,
        hisW/6,
        hisBtnH
    hisDir1.x,hisDir1.y,hisDir1.w,hisDir1.h=
        (hisX+gap+wordW)/2+(hisW/6+hisBtnH+gap/2)/2-hisBtnH/2,
        hisY+hisH+hisBtnH/2-gap/2,
        hisBtnH,
        hisBtnH
    hisType2.x,hisType2.y,hisType2.w,hisType2.h=hisType1.x+hisW/2,hisType1.y,hisType1.w,hisType1.h
    hisDir2.x,hisDir2.y,hisDir2.w,hisDir2.h=hisDir1.x+hisW/2,hisDir1.y,hisDir1.w,hisDir1.h
    inputBox:reset()
    hisBox1:reset() hisType1:reset() hisDir1:reset()
    hisBox2:reset() hisType2:reset() hisDir2:reset()
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
            local str=GenerateCode(data)
            love.system.setClipboardText(str)
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
        if love.keyboard.isDown('lctrl','rctrl') then
            hisBox1:scroll(10,0)
        elseif love.keyboard.isDown('lalt','ralt') then
            hisBox2:scroll(10,0)
        else
            inputBox:setText(lastGuess and lastGuess.word or '')
        end
    elseif key=='down' then
        if love.keyboard.isDown('lctrl','rctrl') then
            hisBox1:scroll(-10,0)
        elseif love.keyboard.isDown('lalt','ralt') then
            hisBox2:scroll(-10,0)
        else
            inputBox:setText('')
        end
    elseif key=='z' and love.keyboard.isDown('lctrl','rctrl') then
        hisType1.code()
    elseif key=='x' and love.keyboard.isDown('lctrl','rctrl') then
        hisDir1.code()
    elseif key=='z' and love.keyboard.isDown('lalt','ralt') then
        hisType2.code()
    elseif key=='x' and love.keyboard.isDown('lalt','ralt') then
        hisDir2.code()
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

function scene.update()
    if TASK.lock("playing_second_check",0.626) and inputBox._value~=lastInput then
        lastInput=inputBox._value
        if lastInput=="" then
            for i=1,#history do
                local g=history[i]
                g.wordLight=""
                g.textObjLight:set("")
            end
        else
            for i=1,#history do
                local g=history[i]
                if find(history[i].word,lastInput) then
                    local w=g.word
                    local w2=rep(" ",#w)
                    local j=1
                    repeat
                        local s,e=find(w,lastInput,j,true)
                        if s then
                            local capture=sub(w,s,e)
                            w2=paste(w2,capture,s)
                            j=s+1
                        else
                            break
                        end
                    until j>#w
                    g.wordLight=w2
                    g.textObjLight:set(w2)
                else
                    g.wordLight=""
                    g.textObjLight:set("")
                end
            end
        end
    end
end

function scene.draw()
    gc_replaceTransform(SCR.xOy_ul)

    -- Draw words
    FONT.set(30)
    if lastGuess then
        gc.translate(20,80)
        local item=lastGuess
        gc_setColor(COLOR.DL)
        setFont(10)
        GC.mStr("ID",40,-7)
        GC.mStr("Rank",120,-7)

        gc_setColor(COLOR.L)
        setFont(25)
        GC.mStr(item.id,40,6)
        if item.rank then
            gc_setColor(item.rankColor)
            GC.mStr(item.rank,120,6)
        end

        local t=item.textObj
        local l=#item.word
        local k=math.log(l,2.6)/l*4
        local anchorY=t:getHeight()*.5
        gc_setColor(COLOR.L)
        gc_draw(t,180,18,nil,k,nil,0,anchorY)
        gc_draw(t,180.5,18,nil,k,nil,0,anchorY)

        gc_setColor(item.bgColor)
        GC.setAlpha(1)
        gc_print(item.info,550,6)
    end

    gc_replaceTransform(SCR.xOy_r)
    gc_translate(-SCR.w/SCR.k*0.15,0)
    gc_setLineWidth(2)
    gc_setColor(COLOR.L)
    gc_circle('line',0,0,140)-- Max area
end

scene.widgetList={
    inputBox,
    hisBox1,hisType1,hisDir1,
    hisBox2,hisType2,hisDir2,
    WIDGET.new{type='button_fill',pos={1,1},text='Give up',x=-225,y=-50,w=130,h=70,fontSize=20,code=WIDGET.c_pressKey'='},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}

return scene
