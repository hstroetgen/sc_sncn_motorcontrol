/**
 * @file watchdog.xc
 * @brief Watchdog Implementation
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <xs1.h>
#include <watchdog_service.h>

[[combinable]]
 void watchdog_service(WatchdogPorts &watchdog_ports, interface WatchdogInterface server i_watchdog[2], int ifm_tile_usec)
{
    unsigned int usec;
    if(ifm_tile_usec==250)
    {
        //Set freq to 250MHz (always needed for proper timing)
        write_sswitch_reg(get_local_tile_id(), 8, 1); // (8) = REFDIV_REGNUM // 500MHz / ((1) + 1) = 250MHz
        usec = 250;
    }
    else
    {
        usec = 100;
    }

    enum {DC100_DC300, DC500, DC1K_DC5K};

    int IFM_module_type = -1;

    unsigned int wd_half_period = 40 * usec;

    unsigned char led_motor_on_wdtick_wden_buffer = 0b1000;
    unsigned char reset_wd_en_mask = 0b1110;
    unsigned char   set_wd_en_mask = 0b0001;

    unsigned char p_ifm_wdtick = 0b0000;
    unsigned char reset_wd_tick_mask = 0b0000;
    unsigned char   set_wd_tick_mask = 0b0001;

    unsigned char reset_led_mask = 0b0111;
    unsigned char   set_led_mask = 0b1000;

    unsigned char   set_motor_on_mask = 0b0100;
    unsigned char   fault_mask = 0b1000;
    //CPLD
    unsigned cpld_out_state = 0x8;//set green LED off
    unsigned int cycles_counter = 0;

    int WD_En_sent_flag =0;
    unsigned int wd_enabled = 0;
    unsigned int ts;
    timer t;

    unsigned int LED_counter = 0;
    int fault=0;//FIXME: this variable should be initialized to 0. here it is 3 to check the LED flashing of WD task
    int fault_counter=0;

    //proper task startup
    t :> ts;
    t when timerafter (ts + (1000*20*250)) :> void;//FixMe: how is it proper?

    //Do the IFM type identification only once
    if(!isnull(watchdog_ports.p_shared_enable_tick_led)){//DC100, DC300, or DC1K
        if(!isnull(watchdog_ports.p_tick)){
            IFM_module_type = DC100_DC300;
        } else {
            IFM_module_type = DC1K_DC5K;
        }
    }
    else if(!isnull(watchdog_ports.p_cpld_shared)){//DC500
        IFM_module_type = DC500;
    }

    /* WD Initialization routine */
    switch(IFM_module_type){
        case DC100_DC300:
            //Enable WD
            led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
            //set green LED on
            led_motor_on_wdtick_wden_buffer |= 0b1010;
            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
            wd_enabled = 1;
            break;
        case DC500:
            //motor on
            led_motor_on_wdtick_wden_buffer |= set_motor_on_mask;
            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

            //reset WD_EN and LED
            led_motor_on_wdtick_wden_buffer &= reset_led_mask;
            led_motor_on_wdtick_wden_buffer &= reset_wd_en_mask;

            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

            //Enable WD
            led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
            wd_enabled = 1;
            break;
        case DC1K_DC5K:
            cpld_out_state &= 0b0111;//turn green LED on
            cpld_out_state |= 0b0101;//enable CPLD, reset errors
            watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;
            cycles_counter = 40;
            wd_enabled = 1;
            break;
    }
#if 0
    /* WD Initialization routine */
    if(!isnull(watchdog_ports.p_shared_enable_tick_led)){

        if(!isnull(watchdog_ports.p_tick)){//DC100 & DC300
            //Enable WD
            led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
            //set green LED on
            led_motor_on_wdtick_wden_buffer |= 0b1010;
            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
        }
        else//DC1K & DC5K
        {
            //motor on
            led_motor_on_wdtick_wden_buffer |= set_motor_on_mask;
            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

            //reset WD_EN and LED
            led_motor_on_wdtick_wden_buffer &= reset_led_mask;
            led_motor_on_wdtick_wden_buffer &= reset_wd_en_mask;

            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

            //Enable WD
            led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
        }

        //enable tick
        wd_enabled = 1;
    }
    else if(!isnull(watchdog_ports.p_cpld_shared)){//[B3, B2, B1, B0] -> [green_LED, CPLD_Enable (active high), WD_Tick (rising_edge), fault_reset (ative high)]

        cpld_out_state &= 0b0111;//turn green LED on
        cpld_out_state |= 0b0101;//enable CPLD, reset errors
        watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;
        cycles_counter = 40;

        //enable tick
        wd_enabled = 1;
    }
#endif

    t :> ts;
    t when timerafter (ts + 100*usec) :> void;//100 us


    t :> ts;

    // Loop forever processing commands
    while (1) {
        select {
        case i_watchdog[int i].status() -> {int status}:
                status = ACTIVE;
                break;

                //FixMe: this call is absolete, should be removed
        case i_watchdog[int i].start(): // produce a rising edge on the WD_EN
                wd_enabled = 1;
                break;

                //FixMe: this call is absolete, should be removed
        case i_watchdog[int i].stop():
                // Disable the kicking
                wd_enabled = 0;
                break;

        case i_watchdog[int i].protect(int fault_id):
                switch(IFM_module_type){
                    case DC100_DC300:
                        //Disable WD and set red LED on
                        led_motor_on_wdtick_wden_buffer &= 0b1100;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                        break;
                    case DC500:
                        cpld_out_state |= 0b1000;//set green LED off
                        watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;
                        break;
                    case DC1K_DC5K:
                        led_motor_on_wdtick_wden_buffer &= fault_mask;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                        break;
                }

#if 0
                if(!isnull(watchdog_ports.p_shared_enable_tick_led)){//All IFM except for DC500
                    led_motor_on_wdtick_wden_buffer &= fault_mask;
                    watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

                    if (!isnull(watchdog_ports.p_tick))//DC100 & DC300
                    {
                        //Disable WD and set red LED on
                        led_motor_on_wdtick_wden_buffer &= 0b1100;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                    }
                }
                else if(!isnull(watchdog_ports.p_cpld_shared)){ //DC500
                    cpld_out_state |= 0b1000;//set green LED off
                    watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;
                }
#endif
                fault=fault_id;
                wd_enabled = 0;
                break;

        case t when timerafter(ts + wd_half_period) :> void://clocking

                t :> ts;
                if (wd_enabled == 1)
                {
                    switch(IFM_module_type){
                        case DC100_DC300:
                            p_ifm_wdtick ^= 1;
                            watchdog_ports.p_tick <: p_ifm_wdtick;
                            break;
                        case DC500:
                            cpld_out_state ^= (1 << 1); //togle wd tick
                            watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;

                            //keep fault reset pin high for some number of cycles to charge the cap
                            if(cycles_counter > 0){
                                cycles_counter--;
                                if(!cycles_counter){//drive reset pin down
                                    cpld_out_state &= 0b1110;
                                    watchdog_ports.p_cpld_shared <: cpld_out_state;
                                }
                            }
                            break;
                        case DC1K_DC5K://FixMe: reduce conditionals
                            if ((led_motor_on_wdtick_wden_buffer & 0b0010) == 0)
                                led_motor_on_wdtick_wden_buffer |= 0b0010;
                            else
                                led_motor_on_wdtick_wden_buffer &= 0b1101;

                            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                            break;
                    }

#if 0
                    if (!isnull(watchdog_ports.p_tick))
                    {
                        p_ifm_wdtick ^= 1;
                        watchdog_ports.p_tick <: p_ifm_wdtick;
                    }
                    else
                    {
                        if ((led_motor_on_wdtick_wden_buffer & 0b0010) == 0)
                            led_motor_on_wdtick_wden_buffer |= 0b0010;
                        else
                            led_motor_on_wdtick_wden_buffer &= 0b1101;

                        if(!isnull(watchdog_ports.p_shared_enable_tick_led))
                            watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                    }
#endif
                    //FixMe: what is that for? Toggling flip-flop?
                    if (WD_En_sent_flag<2)
                    {
                        if ((led_motor_on_wdtick_wden_buffer & set_wd_en_mask) == 0)
                            led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
                        else
                            led_motor_on_wdtick_wden_buffer &= reset_wd_en_mask;

                        if(!isnull(watchdog_ports.p_shared_enable_tick_led)) watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

                        WD_En_sent_flag++;
                    }
#if 0
                    //CPLD wd tick
                    if(!isnull(watchdog_ports.p_cpld_shared)){

                        cpld_out_state ^= (1 << 1); //togle wd tick

                        watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;

                        //keep fault reset pin high for some number of cycles to charge the cap
                        if(cycles_counter > 0){
                            cycles_counter--;
                            if(!cycles_counter){//drive reset pin down
                                cpld_out_state &= 0b1110;
                                watchdog_ports.p_cpld_shared <: cpld_out_state;
                            }
                        }
                    }
#endif
                }

                LED_counter++;
                if (LED_counter >= 15000)
                {
                    LED_counter=0;
                    fault_counter++;
                    if(fault==0)
                    {
//FixMe: check the behavoiur on other DC boards
#if 0
                        led_motor_on_wdtick_wden_buffer ^= (1 << 3);//toggling LED
#endif
                        LED_counter=14000;
                    }
                    //showing the fault type by LED flashing (once, twice, ..., five times)
                    if(fault==1)
                    {
                        if(!isnull(watchdog_ports.p_tick))
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                        }
                        else
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                        }
                    }
                    if(fault==2)
                    {
                        if(!isnull(watchdog_ports.p_tick))
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                        }
                        else
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                        }

                    }
                    if(fault==3)
                    {
                        if(!isnull(watchdog_ports.p_tick))
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==10)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==11)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                        }
                        else
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==10)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==11)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                        }
                    }
                    if(fault==4)
                    {
                        if(!isnull(watchdog_ports.p_tick))
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==10)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==11)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==12)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==13)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                        }
                        else
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==10)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==11)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==12)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==13)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                        }
                    }
                    if(fault==5)
                    {
                        if(!isnull(watchdog_ports.p_tick))
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==10)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==11)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==12)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==13)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==14)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==15)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                        }
                        else
                        {
                            if(fault_counter== 5)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 6)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 7)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter== 8)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter== 9)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==10)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==11)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==12)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==13)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                            if(fault_counter==14)   led_motor_on_wdtick_wden_buffer |= set_led_mask;
                            if(fault_counter==15)   led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                        }
                    }
                    if(!isnull(watchdog_ports.p_shared_enable_tick_led)) watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                    if(fault_counter==20) fault_counter=0;
                }

                break;

        case i_watchdog[int i].reset_faults():

                led_motor_on_wdtick_wden_buffer = 0b1000;
                p_ifm_wdtick = 0b0000;
                WD_En_sent_flag =0;
                LED_counter = 0;
                fault=0;
                fault_counter=0;

                switch(IFM_module_type){
                    case DC100_DC300://ToDo: this needs to be tested!
                        //reset WD_EN and LED
                        led_motor_on_wdtick_wden_buffer &= 0b0000;
                        //Turn green LED on and enable WD
                        led_motor_on_wdtick_wden_buffer |= 0b1011;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                        break;
                    case DC500:
                        cpld_out_state &= 0b0111;//turn green LED on
                        cpld_out_state |= 0b0101;//enable CPLD, reset errors
                        watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;
                        cycles_counter = 40;
                        break;
                    case DC1K_DC5K://FixMe: optimize the code. Why do we write 3 times?
                        //motor on
                        led_motor_on_wdtick_wden_buffer |= set_motor_on_mask;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                        //reset WD_EN and LED
                        led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                        led_motor_on_wdtick_wden_buffer &= reset_wd_en_mask;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                        //Enable WD
                        led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
                        watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;
                        break;
                }
#if 0
                //motor on
                led_motor_on_wdtick_wden_buffer |= set_motor_on_mask;
                if(!isnull(watchdog_ports.p_shared_enable_tick_led)) watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

                //reset WD_EN and LED
                led_motor_on_wdtick_wden_buffer &= reset_led_mask;
                led_motor_on_wdtick_wden_buffer &= reset_wd_en_mask;

                if(!isnull(watchdog_ports.p_shared_enable_tick_led)) watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

                //Enable WD
                led_motor_on_wdtick_wden_buffer |= set_wd_en_mask;
                if(!isnull(watchdog_ports.p_shared_enable_tick_led)) watchdog_ports.p_shared_enable_tick_led <: led_motor_on_wdtick_wden_buffer;

                //CPLD
                if(!isnull(watchdog_ports.p_cpld_shared)){
                    cpld_out_state &= 0b0111;//turn green LED on
                    cpld_out_state |= 0b0101;//enable CPLD, reset errors
                    watchdog_ports.p_cpld_shared <: cpld_out_state & 0xf;
                    cycles_counter = 40;
                }
#endif
                wd_enabled = 1;
                t :> ts;
                t when timerafter (ts + 100*usec  ) :> void;//100 us
                t :> ts;
                break;
        }
    }
}
