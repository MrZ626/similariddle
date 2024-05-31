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

--- @class particle
--- @field answer? true
--- @field word love.Text
--- @field alpha number
--- @field angle number
--- @field aThres number
--- @field dist number
--- @field va number
--- @field size number
--- @field color Zenitha.Color

local debug

local GC=GC
local gc=love.graphics
local gc_replaceTransform,gc_translate,gc_rotate=gc.replaceTransform,gc.translate,gc.rotate
local gc_setColor=gc.setColor
local gc_draw,gc_rectangle,gc_circle=gc.draw,gc.rectangle,gc.circle
local gc_print,gc_printf=gc.print,gc.printf
local gc_push,gc_pop=gc.push,gc.pop
local getFont,setFont=FONT.get,FONT.set
local sin,cos=math.sin,math.cos
local max,min=math.max,math.min
local floor,abs=math.floor,math.abs
local ins=table.insert
local find,sub,rep,paste=string.find,string.sub,string.rep,STRING.paste

local methodName={"score","id","word","length"}
local dirName={'ascend','descend'}

local defaultSortMethod={
    {
        {"score",'descend'},
        {"word",'descend'},
    },
    {
        {"id",'ascend'},
        {"word",'descend'},
    },
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
--- @type string|false
local result
--- @type guess?
local lastGuess
--- @type table<number|string,guess>
local history
--- @type table<table<guess>>
local viewHistory={}
--- @type particle[]
local particles={}
--- @type number

local hisSortMethods={}
local hisViewCount=2
local lastInput

local hisSortMethod
local function hisSortFunc(g1,g2)
    for i=1,#hisSortMethod do
        local v1,v2=g1[hisSortMethod[i][1]],g2[hisSortMethod[i][1]]
        if v1~=v2 then
            return v1<v2==(hisSortMethod[i][2]=='ascend')==(hisSortMethod[i][1]=="score")
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
    if not AnsWordHashMap[w] then
        MSG.new('info',"Word \""..w.."\" doesn't exist",0.5)
        return
    end
    if history[w] then
        lastGuess=history[w]
        -- MSG.new('info',"Already guessed that word!",0.5)
        return true
    end

    local score,info,_result
    if #w<=#data.word/2 or #w>=#data.word*2 then
        score=-26
        info="X"
    else
        score=GetSimilarity(data.model,data.word,w)
        info=string.format("%.2f%%",100*score)
        if w==data.word then
            if giveup then
                _result='gaveup'
                -- TODO: give up
                info="Give Up"
            else
                _result='win'
                if data.daily and not GameData.dailyPassed then
                    GameData.dailyPassed=true
                    GameData.dailyCount=GameData.dailyCount+1
                    SaveData()
                else
                    -- TODO: normal win
                end
                MSG.new('check',"You got it right!",2.6)
            end
        end
    end
    local id=#history+1
    local ansListRank=wordRankHashtable[w]
    local rank
    if ansListRank then
        rank=ansListRank
    else
        local l,r=1,#AnsWordList
        while l<r do
            local m=floor((l+r)/2)
            if score<AnsWordList[m].score then
                l=m+1
            else
                r=m
            end
        end
        rank=l
    end
    lastGuess={
        id=id,
        word=w,
        length=#w,
        score=score,
        info=info,
        rank=rank<1000 and rank or floor(rank/1000).."k",
        textObj=gc.newText(getFont(25),w),
        bgColor={1-score,1+score,1-math.abs(score),.26},
        rankColor=ansListRank and COLOR.L or COLOR.LD,
        idFont=id<100 and 15 or id<1000 and 10 or 7,
        wordLight="",
        textObjLight=gc.newText(getFont(25),""),
    }
    history[id]=lastGuess -- [number]
    history[w]=lastGuess  -- [string]
    updateViewHis(lastGuess,nil)

    if rank<=2600 and not result then
        local rate=MATH.iLerp(1,2600,rank)
        local dist=MATH.lerp(22,126,rate)+MATH.rand(-2,12)
        local bright=MATH.lerp(.6,.26,rate)
        local vowelCount=select(2,string.gsub(w,"[aeio]","x"))+select(2,string.gsub(w,"u","x"))*2.6
        local p={
            word=gc.newText(getFont(10),w),
            alpha=0,
            angle=math.random()*MATH.tau,
            aThres=80*.126/dist,
            dist=dist,
            va=(26/dist*(1+1.026^vowelCount)),
            size=(ansListRank and 3 or 2),
            color=ansListRank and
                {1-bright,1,1-bright,0} or
                {bright,bright,bright,0},
        }
        ins(particles,p)
        if _result then
            p.answer=true
            p.aThres=26
            p.dist=0
            p.va=0
            p.color[4]=0
            p.size=0
            if _result=='gaveup' then
                for i=1,3 do
                    p.color[i]=bright
                end
            end
        end
    end
    if _result then result=_result end
    return true
end

--- @type Zenitha.Widget.inputBox
local inputBox=WIDGET.new{type='inputBox',pos={0,0},regex='[a-z]',maxInputLength=41,lineWidth=2}
--- @type Zenitha.Widget.listBox,Zenitha.Widget.listBox
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
    btn.text=hisSortMethods[i][1][2]=='ascend' and "↑" or "↓"
    updateViewHis(nil,i)
    btn:reset()
end
--- @type Zenitha.Widget.button
hisType1=WIDGET.new{type='button',pos={0,0},fontSize=20,code=function() setSortTitle(1,TABLE.next(methodName,hisSortMethods[1][1][1]) or 'score') end,lineWidth=2}
--- @type Zenitha.Widget.button
hisDir1=WIDGET.new{type='button',pos={0,0},code=function() setSortDir(1,TABLE.next(dirName,hisSortMethods[1][1][2]) or 'ascend') end,lineWidth=2}
--- @type Zenitha.Widget.button
hisType2=WIDGET.new{type='button',pos={0,0},fontSize=20,code=function() setSortTitle(2,TABLE.next(methodName,hisSortMethods[2][1][1]) or 'score') end,lineWidth=2}
--- @type Zenitha.Widget.button
hisDir2=WIDGET.new{type='button',pos={0,0},code=function() setSortDir(2,TABLE.next(dirName,hisSortMethods[2][1][2]) or 'ascend') end,lineWidth=2}

local savedWidgets={inputBox,hisBox1,hisType1,hisDir1,hisBox2,hisType2,hisDir2}

---@type Zenitha.Scene
local scene={}

function scene.enter()
    data=TABLE.copyAll(SCN.args[1])

    debug=love.keyboard.isDown('lctrl','rctrl')
    if debug then
        pcall(love._openConsole)
        local text=love.system.getClipboardText()
        if type(text)=='string' then
            text=STRING.trim(text):lower()
            if not text:find('[^a-zA-Z]') then
                data.word=text
            end
        end
    end

    result=false
    lastGuess=nil
    history={}
    for i=1,hisViewCount do
        viewHistory[i]={}
        hisSortMethods[i]=TABLE.copy(defaultSortMethod[i])
    end
    lastInput=""
    TABLE.clear(particles)

    -- Calculate score and sort
    local model,word=data.model,data.word
    for i=1,#AnsWordList do
        local w=AnsWordList[i]
        w._score=(#w.word<=#word/2 or #w.word>=#word*2) and -26 or GetSimilarity(model,word,w.word)
    end
    table.sort(AnsWordList,function(a,b) return a._score>b._score end)

    -- Generate ranks
    local prev={"MrZ",26}
    for i=1,#AnsWordList do
        local cur=AnsWordList[i]
        wordRankHashtable[cur.word]=cur._score==prev._score and wordRankHashtable[prev.word] or i
        prev=cur
    end
    collectgarbage()

    if debug then
        print("--------------------------")
        for i=1,100 do
            local w=AnsWordList[i]
            print(w.src,w.word..string.rep(" ",8-#w.word),("%.4f%%"):format(w._score*100),string.rep("O",w._score*26))
        end
        TASK.new(function()
            DEBUG.yieldUntilNextScene()
            SCN.back()
        end)
    end

    setSortTitle(1,"score")
    setSortDir(1,'descend')
    setSortTitle(2,"id")
    setSortDir(2,'ascend')
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
    for _,v in next,savedWidgets do v:reset() end
end

local function isCtrlDown() return love.keyboard.isDown('lctrl','rctrl') end
local function isAltDown() return love.keyboard.isDown('lalt','ralt') end
function scene.keyDown(key,isRep)
    if key=='return' then
        if isRep then return true end
        local input=inputBox:getText()
        if guess(input) then
            inputBox:setText('')
        end
    elseif key=='=' then
        if isRep then return true end
        if result then return end
        if data.daily then
            MSG.new('info','Never gonna give you up~',1)
        elseif TASK.lock("sureGiveup",1) then
            MSG.new('warn','Press again to give up',0.5)
        else
            guess(data.word,true)
        end
    elseif key=='c' and isCtrlDown() then
        if data.fixed then
            MSG.new('info',"Can't export code in this mode",0.5)
            return
        else
            local str=GenerateCode(data)
            love.system.setClipboardText(str)
            MSG.new('check',"Riddle code copied to clipboard!",1)
        end
    elseif key=='v' and isCtrlDown() then
        local text=love.system.getClipboardText()
        if not text then return end
        inputBox:setText(text:readLine():trim():gsub('[^a-z]',''))
    elseif key=='escape' then
        if isRep then return true end
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",0.5)
        else
            SCN.back()
        end
    -- elseif key=='h' then
    --     guess("wart")
    --     guess("poker")
    --     guess("cooker")
    --     guess("warmer")
    --     guess("walk")
    --     guess("walking")
    --     guess("walks")
    --     guess("walkers")
    --     guess("walker")
    --     guess("parker")
    --     guess("workers")
    --     guess("working")
    --     guess("worked")
    --     guess("warper")
    --     guess("warping")
    --     guess("taking")
    --     guess("take")
    --     guess("taked")
    --     guess("taker")
    --     guess("takers")
    --     guess("talk")
    --     guess("talked")
    --     guess("talker")
    --     guess("talkers")
    --     guess("talking")
    --     guess("berk")
    --     guess("lerp")
    --     -- 583e2d1
    elseif key=='up' then
        if isCtrlDown() then
            hisBox1:scroll(10,0)
        elseif isAltDown() then
            hisBox2:scroll(10,0)
        else
            inputBox:setText(lastGuess and lastGuess.word or '')
        end
    elseif key=='down' then
        if isCtrlDown() then
            hisBox1:scroll(-10,0)
        elseif isAltDown() then
            hisBox2:scroll(-10,0)
        else
            inputBox:setText('')
        end
    elseif key=='z' and isCtrlDown() then
        hisType1.code()
    elseif key=='x' and isCtrlDown() then
        hisDir1.code()
    elseif key=='z' and isAltDown() then
        hisType2.code()
    elseif key=='x' and isAltDown() then
        hisDir2.code()
    elseif key=='left' or key=='right' then
        -- Do nothing
    else
        WIDGET.focus(inputBox)
        return
    end
    return true
end

function scene.update(dt)
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
    local mx,my=love.mouse.getPosition()
    mx,my=SCR.xOy_r:inverseTransformPoint(mx,my)
    mx=mx+SCR.w/SCR.k*0.15
    local mdist=(mx^2+my^2)^.5
    local mangle=math.atan2(my,mx)
    for i=#particles,1,-1 do
        local p=particles[i]
        p.angle=p.angle+p.va*dt
        if result then
            if p.answer then
                p.color[4]=min(p.color[4]+dt/2.6,1)
                p.size=MATH.expApproach(p.size,min(5+(#history)^.5,20),dt)
            else
                p.dist=p.dist-dt*26
                if p.dist<=6 then
                    table.remove(particles,i)
                elseif p.dist<=20 then
                    p.color[4]=MATH.interpolate(6,0,20,.62,p.dist)
                end
            end
        else
            if p.color[4]<.62 then
                p.color[4]=min(p.color[4]+dt/2.6,.62)
            end
        end
        if abs(mdist-p.dist)<=p.size+3 and (mangle-p.angle+p.aThres)%MATH.tau<=2*p.aThres then
            p.alpha=p.answer and 1 or .26
        else
            p.alpha=max(p.alpha-dt/1.626,0)
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

    -- gc_setLineWidth(2)
    -- gc_setColor(COLOR.L)
    -- gc_circle('line',0,0,140) -- Max area

    for i=1,#particles do
        local p=particles[i]
        gc_push('transform')
        gc_translate(p.dist*cos(p.angle),p.dist*sin(p.angle))
        if p.answer then
            local n=7
            local r=MATH.tau/n
            gc_setColor(1,1,1,p.color[4]*.0626)
            gc_push('transform')
            gc_rotate(love.timer.getTime()*1.26)
            for j=0,n-1 do
                gc.arc('fill','pie',0,0,4.2*p.size^1.626,j*r,(j+.5)*r)
            end
            gc_pop()
        end
        gc_setColor(p.color)
        gc_circle('fill',0,0,p.size)
        if p.alpha>0 then
            gc_setColor(1,1,1,p.alpha)
            GC.mDraw(p.word)
        end
        gc_pop()
    end
end

scene.widgetList={
    inputBox,
    hisBox1,hisType1,hisDir1,
    hisBox2,hisType2,hisDir2,
    WIDGET.new{type='button_fill',pos={1,1},text='Give up',x=-225,y=-50,w=130,h=70,fontSize=20,code=WIDGET.c_pressKey'='},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}

return scene
