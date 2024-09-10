local ins,rem=table.insert,table.remove
local max,min=math.max,math.min
local gc=love.graphics

---@type table<any,any>
local bitMap={
    "    ,O   ,    ,   O ,    ,  O,    ,O   , ,   ,O   ,O ,       ,    ,    ,    ,    ,    ,    ,   ,    ,     ,     ,     ,    ,    ,",
    "    ,O   ,    ,   O ,    , O ,    ,O   ,O,  O,O   ,O ,       ,    ,    ,    ,    ,    ,    , O ,    ,     ,     ,     ,    ,    ,",
    " OO ,OOO , OO , OOO , OO , O , OO ,O   , ,   ,O  O,O ,OOO OO ,OOO , OO ,OOO , OOO,O OO, OOO, O ,O  O,O   O,O   O,O   O,O  O,OOOO,",
    "   O,O  O,O  O,O  O ,O  O,OOO,O  O,OOO ,O,  O,O O ,O ,O  O  O,O  O,O  O,O  O,O  O,OO  ,O   ,OOO,O  O,O   O,O   O, O O ,O  O,   O,",
    " OOO,O  O,O   ,O  O ,OOOO, O ,O  O,O  O,O,  O,OO  ,O ,O  O  O,O  O,O  O,O  O,O  O,O   , OO , O ,O  O,O   O,O O O,  O  ,O  O,  O ,",
    "O  O,O  O,O  O,O  O ,O   , O ,O  O,O  O,O,  O,O O ,O ,O  O  O,O  O,O  O,O  O,O  O,O   ,   O, O ,O  O, O O ,O O O, O O ,O  O, O  ,",
    " OO ,OOO , OO , OO O, OOO, O , OOO,O  O,O,  O,O  O, O,O  O  O,O  O, OO ,OOO , OOO,O   ,OOO , OO, OOO,  O  , O O ,O   O, OOO,OOOO,",
    "    ,    ,    ,     ,    , O ,   O,    , ,O O,    ,  ,       ,    ,    ,O   ,   O,    ,    ,   ,    ,     ,     ,     ,   O,    ,",
    "    ,    ,    ,     ,    ,O  ,OOO ,    , , O ,    ,  ,       ,    ,    ,O   ,   O,    ,    ,   ,    ,     ,     ,     ,OOO ,    ,",
}
for i=1,#bitMap do bitMap[i]=STRING.split(bitMap[i],',') end
bitMap=TABLE.transpose(bitMap)
for n=1,#bitMap do
    for y=1,#bitMap[n] do
        bitMap[n][y]=STRING.atomize(bitMap[n][y])
        for i=1,#bitMap[n][y] do
            bitMap[n][y][i]=bitMap[n][y][i]=='O'
        end
    end
end
---@cast bitMap boolean[][][]

local alphabet=STRING.atomize('abcdefghijklmnopqrstuvwxyz')
local kern={}
for _,c in next,alphabet do kern['d'..c]=-1 end
for _,c in next,alphabet do kern['i'..c]=1; kern[c..'i']=1 end
for _,c in next,alphabet do kern['j'..c]=1; kern[c..'j']=-1 end
for _,c in next,alphabet do kern[c..'l']=1 end
TABLE.update(kern,{
    dd=-1,di= 0,dj=-2,dl= 0,
    id= 1,ii= 1,ij= 0,il= 1,
    jd= 1,ji= 1,jj= 0,jl= 1,
    ld= 0,li= 0,lj=-1,ll= 0,
})
-- 交并比参考
local function IoU_demo()
    local compMat={}
    for y=1,26 do
        compMat[y]={}
        for x=1,26 do
            local charX,charY=bitMap[x],bitMap[y]
            if #charX[1]==4 and #charX[1]==#charY[1] then
                local bingCount=0
                local jiaoCount=0
                for i=1,#charX do
                    for j=1,#charX[i] do
                        if charX[i][j] and charY[i][j] then
                            jiaoCount=jiaoCount+1
                            bingCount=bingCount+1
                        elseif charX[i][j] or charY[i][j] then
                            bingCount=bingCount+1
                        end
                    end
                end
                compMat[y][x]=jiaoCount/bingCount
            else
                compMat[y][x]=-1
            end
        end
    end
    local res=""
    for i=1,26 do
        for j=1,26 do
            res=res..("%d"):format(math.floor(compMat[i][j]*100))..','
        end
        res=res..'\n'
    end
    print(res)
end

local arrowImg=(function()
    local imgData=love.image.newImageData(5,7,'rgba4')
    for y=0,6 do
        imgData:setPixel(math.abs(y-3),y,1,1,1,1)
    end
    local img=gc.newImage(imgData)
    img:setFilter('nearest','nearest')
    return img
end)()

---@type Similariddle.LevelData
local levelData

local ansData={
    bitMap={},
    pixelSize=0,
    renderStart=0,
    img=false,
}
local guessData={
    word="",
    bitMap={},
    pixelSize=0,
    renderStart=0,
    img=false,
    state='editing',
}
local win ---@type boolean
local IoU_curve={}

local guessHis ---@type string[]
local guessHisPointer
local stampEnabled ---@type boolean
local stampData ---@type {word:string,img:love.Image,renderStart:number}[][]
local stampPage ---@type number

---@return boolean[][]
local function getWordBitMap(word)
    local wordMap={{},{},{},{},{},{},{},{},{}}
    local prevChar=''
    for _,char in next,STRING.atomize(word) do
        local writeX=kern[prevChar..char] or 0
        -- Add space if dist>0
        if writeX>0 then
            for y=1,#wordMap do
                for _=1,writeX do
                    ins(wordMap[y],false)
                end
            end
            writeX=0
        end
        writeX=#wordMap[1]+writeX
        local charMap=bitMap[char:byte()-96]
        for y=1,#charMap do
            for x=1,#charMap[y] do
                wordMap[y][writeX+x]=wordMap[y][writeX+x] or charMap[y][x]
            end
        end
        prevChar=char
    end
    return wordMap
end

local function BMtoImage(bm)
    local imgData=love.image.newImageData(#bm[1],#bm,'rgba4')
    for y=1,#bm do
        for x=1,#bm[y] do
            if bm[y][x] then
                imgData:setPixel(x-1,y-1,1,1,1,1)
            end
        end
    end
    local img=gc.newImage(imgData)
    img:setFilter('nearest','nearest')
    imgData:release()
    return img
end

local function resetInputState(hard)
    if hard or guessData.state~='editing' then
        guessData.word=""
        guessData.pixelSize=0
        guessData.renderStart=0
        guessData.state='editing'
        guessHisPointer=#guessHis+1
    end
end

local floorPhase=0
local function updateGuessWord(word)
    local _pixelSize=guessData.pixelSize
    local wordMap=getWordBitMap(word)
    guessData.word=word
    guessData.bitMap=wordMap
    guessData.pixelSize=#wordMap[1]
    if #word==0 then
        guessData.renderStart=0
    else
        guessData.img=BMtoImage(wordMap)
        guessData.renderStart=guessData.renderStart-(guessData.pixelSize-_pixelSize)/2
        if guessData.renderStart%1~=0 then
            guessData.renderStart=math.floor(guessData.renderStart+floorPhase)
            floorPhase=1-floorPhase
        end
    end
end

local function getIoU(bm1,s1,bm2,s2)
    local bingCount=0
    local jiaoCount=0
    local e1,e2=s1+#bm1[1]-1,s2+#bm2[1]-1
    for x=min(s1,s2),max(e1,e2) do
        for y=1,#bm1 do
            local x1,x2=x-s1+1,x-s2+1
            if bm1[y][x1] and bm2[y][x2] then
                jiaoCount=jiaoCount+1
                bingCount=bingCount+1
            elseif bm1[y][x1] or bm2[y][x2] then
                bingCount=bingCount+1
            end
        end
    end
    return jiaoCount/bingCount
end

local function guess(word,hisMode,giveup)
    if not AnsWordHashMap[word] then
        MSG.new('info',"Word \""..word.."\" doesn't exist",0.5)
        return
    end
    if hisMode then
        guessHisPointer=TABLE.find(guessHis,word) or #guessHis
    else
        local posInHistory=TABLE.find(guessHis,word)
        if posInHistory then
            MSG.new('info',"You've already guessed \""..word.."\"",0.5)
            guessHisPointer=posInHistory
        else
            ins(guessHis,word)
            if #guessHis>26 then
                rem(guessHis,1)
            end
            guessHisPointer=#guessHis
        end
    end
    TABLE.clear(IoU_curve)
    local maxPos,maxIoU=0,0
    for x=ansData.renderStart-guessData.pixelSize+1,ansData.renderStart+#ansData.bitMap[1]-1 do
        local IoU=getIoU(ansData.bitMap,ansData.renderStart,guessData.bitMap,x)
        ins(IoU_curve,IoU)
        if IoU>maxIoU then
            maxIoU=IoU
            maxPos=x
        end
    end
    if not win and word==levelData.word then
        win=true
        if not giveup then
            MSG.new('check',"Correct!")
        end
    end
    guessData.state='comparing'
    guessData.renderStart=maxPos
end
local function drag(dx)
    guessData.renderStart=MATH.clamp(guessData.renderStart+dx,ansData.renderStart-guessData.pixelSize+1,ansData.renderStart+#ansData.bitMap[1]-1)
end

---@type Zenitha.Scene
local scene={}

function scene.load()
    levelData=TABLE.copyAll(SCN.args[1])
    ---@cast levelData Similariddle.LevelData

    local wordMap=getWordBitMap(levelData.word)
    ansData.bitMap=wordMap
    ansData.pixelSize=#wordMap[1]
    ansData.renderStart=math.floor(-ansData.pixelSize/2)
    ansData.img=BMtoImage(wordMap)

    win=false
    guessHis,guessHisPointer={},1
    stampEnabled,stampData,stampPage=false,{{},{},{},{},{}},1
    resetInputState(true)
end

local dragBuffer=0
local moveRate=12

function scene.mouseDown(x,y,k)
    dragBuffer=0
end
function scene.mouseMove(x,y,dx,_)
    if love.mouse.isDown(1) then
        dragBuffer=dragBuffer+dx
        while math.abs(dragBuffer)>moveRate do
            drag(MATH.sign(dragBuffer))
            dragBuffer=MATH.linearApproach(dragBuffer,0,moveRate)
        end
    end
end
local function isCtrlDown() return love.keyboard.isDown('lctrl','rctrl') end
function scene.keyDown(key,isRep)
    if key=='v' and isCtrlDown() then
        local text=love.system.getClipboardText()
        if not text then return end
        text=text:lower():match('[a-z]+')
        resetInputState()
        updateGuessWord(text)
        if AnsWordHashMap[text] then
            guess(text,false)
        end
    elseif #key==1 and key:match('[a-z]') then
        if isRep then return end
        resetInputState()
        updateGuessWord(guessData.word..key)
    elseif key=='up' then
        if isCtrlDown() then
            if stampEnabled then
                stampPage=MATH.clamp(stampPage-1,1,5)
            end
        elseif guessHis[guessHisPointer-1] then
            updateGuessWord(guessHis[guessHisPointer-1])
            guess(guessHis[guessHisPointer-1],true)
        end
    elseif key=='down' then
        if isCtrlDown() then
            if stampEnabled then
                stampPage=MATH.clamp(stampPage+1,1,5)
            end
        else
            if guessHis[guessHisPointer+1] then
                updateGuessWord(guessHis[guessHisPointer+1])
                guess(guessHis[guessHisPointer+1],true)
            else
                resetInputState()
            end
        end
    elseif key=='left' then
        drag(-1)
    elseif key=='right' then
        drag(1)
    elseif key=='space' then
        if isCtrlDown() and guessData.state=='comparing' then
            local page=stampData[stampPage]
            ins(page,{word=guessData.word,img=guessData.img,renderStart=guessData.renderStart})
            if #page>10 then
                rem(page,1)
            end
            stampEnabled=true
        end
    elseif key=='return' then
        if isRep then return true end
        guess(guessData.word,false)
    elseif key=='=' then
        if isRep or win then return true end
        if levelData.daily then
            MSG.new('info','Never gonna give you up~',1)
        elseif TASK.lock("sureGiveup",1) then
            MSG.new('warn','Press again to give up',0.5)
        else
            updateGuessWord(levelData.word)
            guess(levelData.word,false,true)
        end
    elseif key=='backspace' then
        if isCtrlDown() then
            stampData[stampPage]={}
        elseif #guessData.word>0 then
            resetInputState()
            updateGuessWord(guessData.word:sub(1,-2))
        end
    elseif key=='delete' then
        if isCtrlDown() then
            stampData[stampPage]={}
        else
            resetInputState(true)
        end
    elseif key=='escape' then
        if isRep then return true end
        if TASK.lock('sureBack',1) then
            MSG.new('info',"Press again to quit",0.5)
        else
            SCN.back()
        end
    end
    return true
end

function scene.update(dt)
end

local rectangle=gc.rectangle
function scene.draw()
    FONT.set(20)
    gc.replaceTransform(SCR.xOy_u)
    gc.scale(8)

    -- Separating lines
    gc.setLineWidth(1)
    gc.line(-100,2,100,2)
    gc.line(-100,16,100,16)
    gc.line(-100,30,100,30)

    -- Guess history marks
    gc.setColor(COLOR.DL)
    if guessHisPointer>1 then gc.printf("↑",-55,17,100,'center',nil,.18) end
    if guessHisPointer<=#guessHis then gc.printf("↓",-55,25,100,'center',nil,.18) end
    if guessHisPointer<=#guessHis then gc.printf(guessHisPointer..'/'..#guessHis,-55,21,100,'center',nil,.18) end
    if guessData.pixelSize>0 then
        gc.draw(arrowImg,-60,19.5)
        gc.draw(arrowImg,60,19.5,nil,-1,1)
    end

    -- History
    if #guessHis>0 then
        for i=1,#guessHis do
            gc.setColor(i==guessHisPointer and COLOR.L or COLOR.LD)
            gc.print(guessHis[i],i<=13 and -60 or -40,36+((i-1)%13)*2.6,nil,.1)
        end
    end

    -- Answer word
    if win then
        gc.setColor(0,1,0,.26)
        gc.draw(ansData.img,ansData.renderStart,4)
    end

    -- Stamps
    if stampEnabled then
        gc.setColor(1,1,1,.26)
        gc.print(stampPage..'/5',48,6,nil,.25)
        local page=stampData[stampPage]
        if #page>0 then
            gc.setColor(1,1,1,.1)
            for i=1,#page do
                local stamp=page[i]
                gc.draw(stamp.img,stamp.renderStart,4)
            end
        end
    end

    -- Guess word
    if guessData.pixelSize>0 then
        if isCtrlDown() then
            gc.setColor(1,1,1,.16)
            gc.draw(guessData.img,guessData.renderStart,4)
        end
        gc.setColor(guessData.state=='editing' and COLOR.LD or COLOR.L)
        gc.draw(guessData.img,guessData.renderStart,18)
    end

    if guessData.state=='comparing' then
        -- IoU curve
        gc.push('transform')
        gc.translate(ansData.renderStart-guessData.pixelSize/2+.5,50)
        for i=1,#IoU_curve do
            rectangle('fill',i-1,0,1,-IoU_curve[i]*16)
        end
        gc.setColor(1,.62,.62)
        gc.setLineWidth(0.2)
        rectangle('line',0,0,#IoU_curve,-16)
        gc.pop()

        -- Aligning line
        local x=guessData.renderStart+guessData.pixelSize/2
        gc.setLineWidth(0.2)
        gc.setColor(1,.26,.26)
        gc.line(x,32,x,52)
    end
end

scene.widgetList={
    WIDGET.new{type='button_fill',pos={1,1},text='Give up',x=-225,y=-50,w=130,h=70,fontSize=20,code=WIDGET.c_pressKey'='},
    WIDGET.new{type='button_fill',pos={1,1},text='Back',x=-80,y=-50,w=130,h=70,code=WIDGET.c_pressKey'escape'},
}
return scene
