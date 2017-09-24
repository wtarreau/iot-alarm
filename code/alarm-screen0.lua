-- screen0 displays the current time and the day of week
function screen_show()
  disp_7seg_str(0,0,string.format("%d  %02d%s%02d",twd,th,(ts%2==0) and ":" or " ",tm))
end

function screen_btn1_cb(btn,ev)
  if ev == 0 then return end

  if light_state == LS_IDLE then
    light_set_state(LS_FULL_START)
  elseif light_state < 6 then
    light_set_state(light_state+1)
  else
    light_set_state(LS_IDLE)
  end
  if ev == 1 or ev == 4 then curr_screen=nil end
end

function screen_btn2_cb(btn,ev)
  if ev == 0 then want_screen=1 end
  if ev == 2 then want_screen=2 end
end

function screen_unload()
  screen_show=nil
  screen_btn1_cb=nil
  screen_btn2_cb=nil
  screen_unload=nil
end
