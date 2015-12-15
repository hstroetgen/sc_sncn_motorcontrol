/**
 * @file commutation_server.h
 * @brief Commutation Loop based on sinusoidal commutation method
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#define ERROR 0
#define SUCCESS 1

typedef enum { STAR_WINDING=1, DELTA_WINDING } BLDCWindingType;
typedef enum { BDC_MOTOR = 10, BLDC_MOTOR = 11 } MotorType;

typedef struct {
    MotorType motor_type;
    BLDCWindingType bldc_winding_type;
    int hall_offset_clk;
    int hall_offset_cclk;
    int commutation_loop_period;
} MotorcontrolConfig;

#ifdef __XC__

#include <watchdog_service.h>
#include <hall_service.h>
#include <qei_service.h>

#include <internal_config.h>

typedef struct {
    port ?p_coast;
    out port ?p_esf_rst_pwml_pwmh;
    port ?p_ff1;
    port ?p_ff2;
} FetDriverPorts;

interface MotorcontrolInterface{
    /**
     * @brief Lorem ipsum...
     *
     * @return Lorem ipsum...
     */
    int checkBusy();
    /**
     * @brief Lorem ipsum...
     *
     * @param voltage Lorem ipsum...
     */
    void setVoltage(int voltage);
    /**
     * @brief Lorem ipsum...
     *
     * @param parameters Lorem ipsum...
     */
    void setParameters(MotorcontrolConfig parameters);
    /**
     * @brief Lorem ipsum...
     *
     * @return Lorem ipsum...
     */
    MotorcontrolConfig getConfig();
    /**
     * @brief Lorem ipsum...
     *
     * @param sensor Lorem ipsum...
     */
    void setSensor(int sensor);
     /**
     * @brief Lorem ipsum...
     */
    void disableFets();
    /**
     * @brief Lorem ipsum...
     */
    void enableFets();
    /**
     * @brief Lorem ipsum...
     *
     * @return Lorem ipsum...
     */
    int getFetsState();
    /**
     * @brief Lorem ipsum...
     *
     * @param hall_config Lorem ipsum...
     * @param qei_config Lorem ipsum...
     * @param commutation_config Lorem ipsum...
     * @param in_nominal_speed Lorem ipsum...
     */
    void setAllParameters(HallConfig hall_config, QEIConfig qei_config, MotorcontrolConfig commutation_config, int in_nominal_speed);
};

/**
 * @brief Sinusoidal based Commutation Loop
 *
 * @param fet_driver_ports Lorem ipsum...
 * @param motorcontrol_config Lorem ipsum...
 * @param c_pwm_ctrl channel to set PWM level output to motor phases
 * @param i_hall Lorem ipsum...
 * @param i_qei Lorem ipsum...
 * @param i_watchdog Lorem ipsum...
 * @param i_motorcontrol[5] Lorem ipsum...
 *
 */
[[combinable]]
void motorcontrol_service(FetDriverPorts &fet_driver_ports, MotorcontrolConfig &motorcontrol_config,
                            chanend c_pwm_ctrl,
                            interface HallInterface client ?i_hall,
                            interface QEIInterface client ?i_qei,
                            interface WatchdogInterface client i_watchdog,
                            interface MotorcontrolInterface server i_motorcontrol[5]);

#endif
