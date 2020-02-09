-- debounced button states (0=pressed,1=released), time counts, and callbacks.
-- Callbacks : function(btn,0/1/2/3/4) for release/press/long/repeat/stop.
-- Note: "stop" is sent instead of "release" after "repeat"/"long" so that
-- "release" is a release after a short press only. "long" is handled by a
-- timer and automatically repeats every 200ms with the "repeat" event.
-- btn_cnt is 0 on release and starts at 1 when pressed, and caps to 5 (1 sec).
-- It's enough to detect a press. It uses timer #2.
local btn_state={1,1}
local btn_cnt={0,0}

-- this are the callbacks to set from outside
btn_cb={}

-- low level button handlers
local function btn_trig(btn,lev)
  local ev
  if btn_state[btn] ~= lev then
    btn_state[btn] = lev
    if lev == 1 then
      ev=btn_cnt[btn] < 5 and 0 or 4
      btn_cnt[btn]=0
    elseif lev == 0 and btn_cnt[btn] == 0 then
      ev=1
      btn_cnt[btn]=1
    end
    if ev ~= nil and btn_cb[btn] ~= nil then
      btn_cb[btn](btn, ev)
    end
  end
end

if brd_btn1 and debounce then
  gpio.trig(brd_btn1,"both",function()
    btn_trig(1,debounce(brd_btn1))
  end)
end

if brd_btn2 and debounce then
  gpio.trig(brd_btn2,"both",function()
    btn_trig(2,debounce(brd_btn2))
  end)
end

local btn_tmr = tmr.create()
btn_tmr:alarm(200,tmr.ALARM_AUTO,function()
  local btn
  for btn=1,2 do
    if btn_cnt[btn] == 5 then
      if btn_cb[btn] ~= nil then btn_cb[btn](btn,3) end
    elseif btn_cnt[btn] > 0 then
      btn_cnt[btn]=btn_cnt[btn]+1
      if btn_cnt[btn] == 5 and btn_cb[btn] ~= nil then btn_cb[btn](btn,2) end
    end
  end
end)
