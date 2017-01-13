/* PLEASE REPLACE "CORE_BOARD_REQUIRED" AND "IFM_BOARD_REQUIRED" WITH AN APPROPRIATE BOARD SUPPORT FILE FROM module_board-support */
#include <CORE_C22-rev-a.bsp>
#include <IFM_DC1K-rev-c3.bsp>


/**
 * @brief Test illustrates usage of module_commutation
 * @date 17/06/2014
 */

//#include <pwm_service.h>
#include <pwm_server.h>
#include <user_config.h>
#include <watchdog_service.h>

#include <xscope.h>
#include <timer.h>
#include <stdio.h>
#include <print.h>

PwmPortsGeneral pwm_ports = SOMANET_IFM_PWM_PORTS_GENERAL;
WatchdogPorts wd_ports = SOMANET_IFM_WATCHDOG_PORTS;
FetDriverPorts fet_driver_ports = SOMANET_IFM_FET_DRIVER_PORTS;

void send_pwm_values(client interface update_pwm_general i_update_pwm)
{
    #define PWM_MAX_VALUE   5650
    #define PWM_MIN_VALUE   0

    timer t;
    unsigned int time=0x00000000;
    unsigned int period = 10000;

    unsigned short  pwm_value_a = 0x0000, pwm_value_b = 0x0000, pwm_value_c = 0x0000,
                    pwm_value_u = 0x0000, pwm_value_v = 0x0000, pwm_value_w = 0x0000;

    short pwm_delta =0x0000;
    unsigned short pwm_value=0;

    unsigned short pwm_limit_low  = 0x0000;
    unsigned short pwm_limit_high = 0x0000;

    pwm_limit_high= PWM_MAX_VALUE;
    pwm_limit_low = PWM_MIN_VALUE;

    pwm_delta = 1;
    pwm_value = PWM_MIN_VALUE;

    time    =0x00000000;
    t :> time;
    while(1)
    {
        select
        {
        case t when timerafter(time) :> void:

            pwm_value_a &= 0x0000FFFF;
            pwm_value_b &= 0x0000FFFF;
            pwm_value_c &= 0x0000FFFF;
            pwm_value_u &= 0x0000FFFF;
            pwm_value_v &= 0x0000FFFF;
            pwm_value_w &= 0x0000FFFF;
            i_update_pwm.update_server_control_data(
                    /*unsigned short pwm_a*/pwm_value_a, /*unsigned short pwm_b*/pwm_value_b, /*unsigned short pwm_c*/pwm_value_c,
                    /*unsigned short pwm_u*/pwm_value_u, /*unsigned short pwm_v*/pwm_value_v, /*unsigned short pwm_w*/pwm_value_w,
                    /*received_pwm_on (not activated)*/0, /*recieved_safe_torque_off_mode  (not activated)*/0);

             pwm_value += pwm_delta;
             if(pwm_value>pwm_limit_high)
             {
                 pwm_value=pwm_limit_high;
                 pwm_delta = -1;
             }

             if(pwm_value<pwm_limit_low)
             {
                 pwm_value=pwm_limit_low;
                 pwm_delta = 1;
             }

             pwm_value_a = pwm_value;
             pwm_value_b = pwm_value;
             pwm_value_c = pwm_value;
             pwm_value_u = pwm_value;
             pwm_value_v = pwm_value;
             pwm_value_w = pwm_value;

             time     += period;
            break;
        }
    }
}

int main(void) {

    interface WatchdogInterface i_watchdog[2];
    interface update_pwm_general i_update_pwm;

    par
    {
        on tile[IFM_TILE]:
        {
            par
            {
                {
                    delay_milliseconds(1000);
                    send_pwm_values(i_update_pwm);
                }

                /* PWM Service */
                {
                    pwm_config_general(pwm_ports);

                    delay_milliseconds(500);
                    pwm_service_general(
                            pwm_ports, i_update_pwm,
                            DUTY_START_BRAKE, DUTY_MAINTAIN_BRAKE, PERIOD_START_BRAKE,
                            IFM_TILE_USEC, COMMUTATION_FRQ);

                }

                /* Watchdog Service */
                {
                    delay_milliseconds(200);
                    watchdog_service(wd_ports, i_watchdog, IFM_TILE_USEC);
                }
            }
        }
    }

    return 0;
}
