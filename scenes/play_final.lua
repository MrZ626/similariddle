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

local font=love.graphics.newImageFont('alphabet_o.png','abcdefghijklmnopqrstuvwxyz',0)
font:setFilter('nearest','nearest')

local ins,rem=table.insert,table.remove

local gc=love.graphics

---@type Similariddle.LevelData
local levelData

local ansData={
    bitMap={},
    pixelSize=0,
    bias=0,
    renderStart=0,
}
local guessData={
    word="",
    bitMap={},
    pixelSize=0,
    bias=0,
    renderStart=0,
    boundL=false,
    boundR=false,
    state='editing',
}
local IoU_curve={}

local function getWordMap(word)
    local wordMap={{},{},{},{},{},{},{},{},{}}
    for _,char in next,STRING.atomize(word) do
        local charMap=bitMap[char:byte()-96]
        for y=1,#charMap do
            for x=1,#charMap[y] do
                ins(wordMap[y],charMap[y][x])
            end
        end
    end
    return wordMap
end

local floorPhase=0
local function updateGuessWord(word)
    local _renderStart=guessData.renderStart
    local _pixelSize=guessData.pixelSize
    local wordMap=getWordMap(word)
    guessData.word=word
    guessData.bitMap=wordMap
    guessData.pixelSize=#wordMap[1]
    if #word==0 then
        guessData.renderStart=0
    else
        guessData.renderStart=_renderStart-(guessData.pixelSize-_pixelSize)/2
        if guessData.renderStart%1~=0 then
            guessData.renderStart=math.floor(guessData.renderStart+floorPhase)
            floorPhase=1-floorPhase
        end
    end
    guessData.state='editing'
end

local function getIoU(bm1,s1,bm2,s2)
    local bingCount=0
    local jiaoCount=0
    local e1,e2=s1+#bm1[1]-1,s2+#bm2[1]-1
    for x=math.min(s1,s2),math.max(e1,e2) do
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

local function guess(w,giveup)
    if not AnsWordHashMap[w] then
        MSG.new('info',"Word \""..w.."\" doesn't exist",0.5)
        return
    end
    TABLE.clear(IoU_curve)
    for x=ansData.renderStart-guessData.pixelSize+1,ansData.renderStart+#ansData.bitMap[1]-1 do
        local IoU=getIoU(ansData.bitMap,ansData.renderStart,guessData.bitMap,x)
        ins(IoU_curve,IoU)
    end
    guessData.boundL,guessData.boundR=ansData.renderStart-guessData.pixelSize+1,ansData.renderStart+#ansData.bitMap[1]-1
    if w==levelData.word then
        if giveup then
            MSG.new('info',"The answer is \""..levelData.word.."\"",1)
        else
            MSG.new('check',"Correct!")
        end
    end
    guessData.state='comparing'
end

local scene={}

function scene.load()
    levelData=TABLE.copyAll(SCN.args[1])
    ---@cast levelData Similariddle.LevelData

    local wordMap=getWordMap(levelData.word)
    ansData.bitMap=wordMap
    ansData.pixelSize=#wordMap[1]
    ansData.renderStart=math.floor(-ansData.pixelSize/2)

    updateGuessWord("")
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
            guessData.renderStart=MATH.clamp(guessData.renderStart+MATH.sign(dragBuffer),ansData.renderStart-guessData.pixelSize+1,ansData.renderStart+#ansData.bitMap[1]-1)
            dragBuffer=MATH.linearApproach(dragBuffer,0,moveRate)
        end
    end
end
function scene.keyDown(key,isRep)
    if #key==1 and key:match('[a-z]') then
        if isRep then return end
        if guessData.state~='editing' then guessData.word="" end
        updateGuessWord(guessData.word..key)
    elseif key=='return' then
        if isRep then return true end
        guess(guessData.word)
    elseif key=='=' then
        if isRep then return true end
        if levelData.daily then
            MSG.new('info','Never gonna give you up~',1)
        elseif TASK.lock("sureGiveup",1) then
            MSG.new('warn','Press again to give up',0.5)
        else
            updateGuessWord(levelData.word)
            guess(levelData.word,true)
        end
    elseif key=='backspace' then
        if #guessData.word>0 then
            if guessData.state~='editing' then guessData.word="" end
            updateGuessWord(guessData.word:sub(1,-2))
        end
    elseif key=='delete' then
        if guessData.state~='editing' then guessData.word="" end
        updateGuessWord("")
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
    -- love.graphics.setFont(font)
    -- gc.print("abcdefghijklmnopqrstuvwxyz",0,0,nil,9.5)

    -- Separating lines
    gc.replaceTransform(SCR.xOy_u)
    gc.scale(8)
    gc.setLineWidth(0.626)
    gc.line(-100,4,100,4)
    gc.line(-100,17,100,17)
    gc.line(-100,31,100,31)

    local wordMap
    -- Answer word
    -- wordMap=ansData.bitMap
    -- gc.replaceTransform(SCR.xOy_u)
    -- gc.scale(8)
    -- gc.translate(ansData.renderStart,5)
    -- for y=1,#wordMap do
    --     for x=1,#wordMap[y] do
    --         if wordMap[y][x] then
    --             rectangle('fill',x,y,1,1)
    --         end
    --     end
    -- end

    -- Guess word
    wordMap=guessData.bitMap
    gc.replaceTransform(SCR.xOy_u)
    gc.scale(8)
    gc.translate(guessData.renderStart,18)
    gc.setColor(guessData.state=='editing' and COLOR.LD or COLOR.L)
    for y=1,#wordMap do
        for x=1,#wordMap[y] do
            if wordMap[y][x] then
                rectangle('fill',x,y,1,1)
            end
        end
    end

    if guessData.state=='comparing' then
        -- IoU curve
        gc.replaceTransform(SCR.xOy_u)
        gc.scale(8)
        gc.translate(ansData.renderStart-guessData.pixelSize/2+.5,50)
        for i=1,#IoU_curve do
            rectangle('fill',i,0,1,-IoU_curve[i]*16)
        end
        gc.setColor(1,.62,.62)
        gc.setLineWidth(0.2)
        rectangle('line',1,0,#IoU_curve,-16)

        -- Aligning line
        gc.replaceTransform(SCR.xOy_u)
        gc.scale(8)
        local x=guessData.renderStart+guessData.pixelSize/2+1
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
