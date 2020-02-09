-- screen2 displays the alarm time
local digit=1

local function screen_show()
  disp_7seg_str(0,0,string.format("%02d:%02d",alarm_h(),alarm_m()),digit)
end

local function screen_btn1_cb(btn,ev)
  local ah,am=alarm_h(),alarm_m()
  if ev == 0 then return end
  if ev == 4 then screen_show() return end

  if ah < 0 or am < 0 then ah=0 am=0
  elseif digit == 1 then   ah=ah+10
  elseif digit == 2 then   ah=ah+1
  elseif digit == 4 then   am=am+10
  elseif digit == 5 then   am=am+1
  end

  if ah > 23 then ah=-1 end
  if am > 59 then am=0 end
  alarm=(ah >= 0) and ah*60+am or -1

  if ev == 1 then screen_show() end
end

local function screen_btn2_cb(btn,ev)
  if ev == 0 then
    digit=(digit >= 5) and 1 or (digit==2) and 4 or (digit+1)
    screen_show()
  end
  if ev == 2 then want_screen=0 end
end

local function screen_unload()
  local G=getfenv()
  G.screen_show=nil
  G.screen_btn1_cb=nil
  G.screen_btn2_cb=nil
  G.screen_unload=nil
end

local G=getfenv()
G.screen_show=screen_show
G.screen_btn1_cb=screen_btn1_cb
G.screen_btn2_cb=screen_btn2_cb
G.screen_unload=screen_unload
