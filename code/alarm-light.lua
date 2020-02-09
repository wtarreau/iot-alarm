-- light states
LS_IDLE=0
LS_FULL_START=1
LS_FULL=2
LS_FULL_STOP=3

-- light state, last change date, last brightness
light_state=LS_IDLE
light_change=0

-- return the time spent in the current state in ms except idle (always 0)
function light_duration()
  local now=tmr.now()
  if light_state == LS_IDLE then return 0 end
  now=now-light_change
  if now < 0 then now=now+1073741824 now=now+1073741824 end
  return math.floor(now / 1000)
end

function light_set_state(state)
  light_change=tmr.now()
  light_state=state
end

-- return the new brightness based on the time spent in the state (0..1023) and
-- adjust transient states.
function light_new_brightness()
  local dur=light_duration()

  if light_state == LS_FULL_START then
    if dur < LIGHT_FULL_TIME then return math.floor(light_duration() * 1023 / LIGHT_FULL_TIME) end
    light_set_state(LS_FULL)
  end

  if light_state == LS_FULL then
     if dur < LIGHT_STAY_TIME then return 1023 end
     light_set_state(LS_FULL_STOP)
  end

  if light_state == LS_FULL_STOP then
    if dur < LIGHT_FULL_TIME then return 1023 - math.floor(light_duration() * 1023 / LIGHT_FULL_TIME) end
     light_set_state(LS_IDLE)
  end

  return 0
end


-- set light's pwm from 0 to 1023 (quadratic curve)
function light_pwm(val)
  val=val < 0 and 0 or val > 1023 and 1023 or val
  val=val*val/1023
  pwm.setduty(brd_pwm, val)
end

-- main
pwm.setup(brd_pwm,500,0)
pwm.start(brd_pwm)
