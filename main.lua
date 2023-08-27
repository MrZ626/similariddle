require'Zenitha'

Zenitha.setAppName('similariddle')
Zenitha.setVersionText(require"version".appVer)
Zenitha.setFirstScene('menu')
Zenitha.setMaxFPS(40) -- Enough!
Zenitha.setClickFX(false)
Zenitha.setDrawCursor(NULL)
Zenitha.setOnFnKeys({NULL, NULL, NULL, NULL, NULL, NULL, love._openConsole})

love.keyboard.setKeyRepeat(true)
if MOBILE then
    love.window.setFullscreen(true)
end

SCR.setSize(1000, 600)

FONT.setDefaultFont('main')
FONT.load('main','codePixel Regular.ttf')
FONT.get(80)

WIDGET._prototype.button.cornerR=0

OptionNames={
    {'CET4','CET6','TEM8','GRE'},
    {'Short','Medium','Long','Loooooong'},
    {'Easy','Medium','Hard','Extreme','Hell'},
}

TitleString="Similariddle"
FakeTitleString="Similariddle"
math.randomseed(tonumber(os.date('%Y%m%d')))
repeat
    local r=math.random(3)
    if r==1 then
        -- change a letter to another
        local changePos=math.random(2,#FakeTitleString-1)
        local pick=math.random(2,#FakeTitleString)
        FakeTitleString=
            FakeTitleString:sub(1,changePos-1)..
            FakeTitleString:sub(pick,pick)..
            FakeTitleString:sub(changePos+1)
    elseif r==2 then
        -- repeat a letter
        local changePos=math.random(2,#FakeTitleString-1)
        FakeTitleString=
            FakeTitleString:sub(1,changePos)..
            FakeTitleString:sub(changePos+1)
    elseif r==3 then
        -- swap two letters
        local changePos=math.random(2,#FakeTitleString-2)
        FakeTitleString=
            FakeTitleString:sub(1,changePos-1)..
            FakeTitleString:sub(changePos+1,changePos+1)..
            FakeTitleString:sub(changePos,changePos)..
            FakeTitleString:sub(changePos+2)
    end
until FakeTitleString~=TitleString

-- Load scene files from SOURCE ONLY
for _, v in next, love.filesystem.getDirectoryItems('scenes') do
    if FILE.isSafe('scenes/' .. v) then
        local sceneName=v:sub(1, -5)
        SCN.add(sceneName, require('scenes.' .. sceneName))
    end
end
