-- debounced button states (0=pressed,1=released), time counts, and callbacks.
-- Callbacks : function(btn,0/1/2/3) for release/press/repeat/stop. Note: "stop"
-- is sent instead of "release" after "repeat" so up is a release after a short
-- press. "hold" is handled by a timer and automatically repeats every 200ms.
-- btn_cnt is 0 on release and starts at 1 when pressed, and caps to 5 (1 sec).
-- It's enough to detect a press. It uses timer #2.
btn_state={1,1}
btn_cnt={0,0}
btn_cb={}

-- low level button handlers
function btn_trig(btn,lev)
  local ev
  if btn_state[btn] ~= lev then
    btn_state[btn] = lev
    if lev == 1 then
      ev=btn_cnt[btn] < 5 and 0 or 3
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

function btn1_trig()
  btn_trig(1,debounce(brd_btn1))
end

function btn2_trig()
  btn_trig(2,debounce(brd_btn2))
end

function btn_repeat()
  local btn
  for btn=1,2 do
    if btn_cnt[btn] == 5 then
      if btn_cb[btn] ~= nil then btn_cb[btn](btn,2) end
    elseif btn_cnt[btn] > 0 then
      btn_cnt[btn]=btn_cnt[btn]+1
    end
  end
end

if brd_btn1 ~= nil then gpio.trig(brd_btn1,"both",btn1_trig) end
if brd_btn2 ~= nil then gpio.trig(brd_btn2,"both",btn2_trig) end
tmr.alarm(2,200,tmr.ALARM_AUTO,btn_repeat)
