/**
 * @file watchdog.xc
 * @brief Watchdog Implementation
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <xs1.h>
#include <watchdog_service.h>

[[combinable]]
void watchdog_service(WatchdogPorts &watchdog_ports, interface WatchdogInterface server i_watchdog[2])
{

    unsigned int wd_enabled = 1, shared_out, tick_out = 0;
    unsigned int ts, ts2;
    timer t;

    t :> ts;

    // Loop forever processing commands
    while (1) {
        select {
            // Get a command from the out loop
                case i_watchdog[int i].start(): // produce a rising edge on the WD_EN

                    if (isnull(watchdog_ports.p_tick)){
                        shared_out = 0xe;
                        shared_out &= ~0x5;//and shortly switch the LED to red (DC1K)
                    }
                    else {
                        shared_out &= ~0x1;
                    }
                    watchdog_ports.p_enable <: shared_out; // go low

                    t :> ts2;
                    t when timerafter(ts2+25000) :> ts2;

                    if (isnull(watchdog_ports.p_tick)){
                        shared_out &= 0x7;
                        shared_out |= 0x1;
                    }
                    else{
                        shared_out |= 0x1;
                    }
                    watchdog_ports.p_enable <: shared_out; // go high

                    t :> ts2;
                    t when timerafter (ts2 + 25000) :> ts2;

                    if (isnull(watchdog_ports.p_tick)){
                        shared_out |= (1 << 2);             // prepare the kicking
                        watchdog_ports.p_enable <: shared_out;
                    }

                    wd_enabled = 1;

                    break;

                case i_watchdog[int i].stop():
                    // Disable the kicking
                    wd_enabled = 0;
                    break;

                case t when timerafter(ts + 250000) :> ts:
                    if (wd_enabled == 1) {
                        if (isnull(watchdog_ports.p_tick)){
                            shared_out ^= (1 << 1) ; //toggle the second bit (DC1K)
                            watchdog_ports.p_enable <: shared_out;
                        }
                        else{
                            tick_out ^= 0x1;
                            watchdog_ports.p_tick <: tick_out;
                        }
                    }
                    break;

            // Do a case: Separate the LED bits from the port XS1_PORT_4B. LSB enable watchdog.
        }
    }
}
