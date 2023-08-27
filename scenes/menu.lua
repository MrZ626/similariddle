local scene={}

function scene.draw()
    FONT.set(80)
    GC.mStr(TitleString,500,120)
    FONT.set(35)
    GC.mStr("By MrZ & Staffhook",500,220)
end

scene.widgetList={
    WIDGET.new{type='button',x=350,y=380,w=260,h=90,fontSize=45,text="Daily",code=playDaily},
    WIDGET.new{type='button_fill',x=650,y=380,w=260,h=90,fontSize=45,text="Custom",code=WIDGET.c_goScn('custom','fastFade')},
}
return scene
