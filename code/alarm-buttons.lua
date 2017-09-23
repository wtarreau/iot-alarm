-- debounced button states
btn1_state=1
btn2_state=1

-- low level button handlers
function btn1_trig()
  local lev=debounce(brd_btn1)
  if btn1_state ~= lev then
    btn1_state = lev
    if btn1_cb ~= nil then btn1_cb() end
  end
end

function btn2_trig()
  local lev=debounce(brd_btn2)
  if btn2_state ~= lev then
    btn2_state = lev
    if btn2_cb ~= nil then btn2_cb() end
  end
end

if brd_btn1 ~= nil then gpio.trig(brd_btn1,"both",btn1_trig) end
if brd_btn2 ~= nil then gpio.trig(brd_btn2,"both",btn2_trig) end
