-- board specific stuff, mostly wiring and device addresses
brd_led_inv=1      -- led inverted (connected to vcc)
brd_led=PIN_GP2    gpio.mode(brd_led, gpio.OUTPUT) gpio.write(brd_led, brd_led_inv)
brd_sda=PIN_GP4    gpio.mode(brd_sda, gpio.OUTPUT) gpio.write(brd_sda, 0)
brd_scl=PIN_GP5    gpio.mode(brd_scl, gpio.OUTPUT) gpio.write(brd_scl, 0)
brd_pwm=PIN_GP14   gpio.mode(brd_pwm, gpio.OUTPUT) gpio.write(brd_pwm, 0)
brd_btn1=PIN_GP12  gpio.mode(brd_btn1, gpio.INPUT, gpio.PULLUP)
brd_btn2=PIN_GP13  gpio.mode(brd_btn2, gpio.INPUT, gpio.PULLUP)

-- OLED display
brd_oled_addr=0x3c
--brd_oled_d="ssd1305_i2c_128x32_noname"
--brd_oled_d="ssd1306_i2c_128x64_noname"
brd_oled_d="ssd1306_i2c_128x32_univision"
brd_oled_w=128
brd_oled_h=32
brd_oled_r=0
