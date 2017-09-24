-- alarm clock application
-- only works with a stripped down firmware (integer, 12 modules)
curr_screen=1  -- set to nil to force an immediate refresh on want_screen
want_screen=0

function load_files(...)
  local arg={...}
  local f
  for f=1,#arg do
    if file.exists(arg[f] .. ".lc") then dofile(arg[f] .. ".lc")
    elseif file.exists(arg[f] .. ".lua") then dofile(arg[f] .. ".lua")
    else print("Missing file " .. arg[f])
    end
  end
end

load_files("alarm-vars","alarm-buttons","alarm-light")

-- a few local variables
light_bright=0

-- returns alarm hour, or -1 if off
function alarm_h()
  return alarm >= 0 and math.floor(alarm/60) or -1
end

-- returns alarm minute, or -1 if off
function alarm_m()
  return alarm >= 0 and alarm%60 or -1
end

-- manages screen and brightness
function refresh()
  local ratio=light_new_brightness()
  local yy,mm,dd,h,m,s,wd=time_get_now()
  local force_refresh

  if m ~= tm then force_refresh=1 end

  if s ~= nil then
    tyy,tmm,tdd,th,tm,ts,twd=yy,mm,dd,h,m,s,wd
    yy,mm,dd,h,m,s,wd=nil,nil,nil,nil,nil,nil,nil
  end

  if curr_screen ~= want_screen then
    if screen_unload ~= nil then screen_unload() end
    curr_screen=want_screen
    btn_cb[1]=nil
    btn_cb[2]=nil
    load_files("alarm-screen" .. curr_screen)
    btn_cb[1]=screen_btn1_cb
    btn_cb[2]=screen_btn2_cb
    force_refresh=1
  end

  if ratio ~= light_bright then
    light_bright=ratio
    light_pwm(ratio)
  end

  if screen_show ~= nil and force_refresh then
    screen_show()
  end
end

-- periodic callback
function tick()
  if light_state == LS_IDLE and th == alarm_h() and tm == alarm_m() then
    light_set_state(LS_FULL_START)
  end
  refresh()
end

-- entry point

tmr.alarm(1,100,tmr.ALARM_AUTO,tick)
btn_cb[1]=screen_btn1_cb
btn_cb[2]=screen_btn2_cb
