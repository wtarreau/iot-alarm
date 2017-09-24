-- displays current date, time, alarm and state. Uses the t* time variables
function screen_show()
  disp_lines(string.format("%04d-%02d-%02d (%d)",tyy,tmm,tdd,twd),
             string.format("%02d:%02d:%02d   [al %02d:%02d]",th,tm,ts,alarm_h(),alarm_m()),
             string.format("state=%d ratio=%d",light_state, light_bright))
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
  if ev ~= 2 then curr_screen=nil end
end

function screen_btn2_cb(btn,ev)
  if ev == 0 then want_screen=0 end
  if ev == 2 then want_screen=2 end
end

function screen_unload()
  screen_show=nil
  screen_btn1_cb=nil
  screen_btn2_cb=nil
  screen_unload=nil
end
