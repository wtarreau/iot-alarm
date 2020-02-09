-- screen0 displays the current time and the day of week
local function screen0_show()
  disp_7seg_str(0,0,string.format("%d  %02d%s%02d",twd,th,(ts%2==0) and ":" or " ",tm))
end

local function screen0_btn1_cb(btn,ev)
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

local function screen0_btn2_cb(btn,ev)
  if ev == 0 then want_screen=1 end
  if ev == 2 then want_screen=2 end
end

local function screen0_unload()
  local G=getfenv()
  G.screen_show=nil
  G.screen_btn1_cb=nil
  G.screen_btn2_cb=nil
  G.screen_unload=nil
end

local function screen0_set()
  local G=getfenv()
  G.screen_show=screen0_show
  G.screen_btn1_cb=screen0_btn1_cb
  G.screen_btn2_cb=screen0_btn2_cb
  G.screen_unload=screen0_unload
end

local G=getfenv()
if G.screen_set then
  G.screen_set[0]=screen0_set
end
