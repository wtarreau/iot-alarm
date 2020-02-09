-- displays current date, time, alarm and state. Uses the t* time variables
local function screen_show()
  disp_lines(string.format("%04d-%02d-%02d (%d)",tyy,tmm,tdd,twd),
             string.format("%02d:%02d:%02d   [al %02d:%02d]",th,tm,ts,alarm_h(),alarm_m()),
             string.format("state=%d ratio=%d",light_state, light_bright))
end

local function screen_btn1_cb(btn,ev)
  if ev == 0 then return end

  if light_state == LS_IDLE then
    light_set_state(LS_FULL_START)
  elseif light_state < 6 then
    light_set_state(light_state+1)
  else
    light_set_state(LS_IDLE)
  end
  if ev == 1 or ev == 4 then screen_show() end
end

local function screen_btn2_cb(btn,ev)
  if ev == 0 then want_screen=0 end
  if ev == 2 then want_screen=2 end
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
