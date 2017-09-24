-- screen2 displays the alarm time
local digit=0

function screen_show()
  disp_7seg_str(0,0,string.format("%02d:%02d",alarm_h(),alarm_m()),digit)
end

function screen_btn1_cb(btn,ev)
  if ev == 0 then return end
  if ev == 3 then curr_screen=nil return end

  if digit == 1 then
    local ah=alarm_h()+10
    local al=alarm_m()
  elseif digit == 2 then
    local ah=alarm_h()+1
    local al=alarm_m()
  elseif digit == 4 then
    local ah=alarm_h()
    local al=alarm_m()+10
  elseif digit == 5 then
    local ah=alarm_h()
    local al=alarm_m()+1
  end

  if ah < 24 then ah=-1 end
  if am < 60 then am=-1 end
  alarm=ah*60+am

  if ev ~= 2 then curr_screen=nil end
end

function screen_btn2_cb(btn,ev)
  if ev == 0 then digit=(digit >= 5) and 0 or (digit==2) and 4 or (digit+1) end
  if ev == 3 then want_screen=0 end
--  alarm = alarm < 0 and 0 or alarm >= 1410 and -1 or (alarm + 30)
--  print("btn2: alarm: ",alarm_h(),":",alarm_m())
--  if ev ~= 2 then
--    curr_screen=nil
--    refresh()
--  end
end

function screen_unload()
  screen_show=nil
  screen_unload=nil
  screen_btn1_cb=nil
  screen_btn2_cb=nil
end
