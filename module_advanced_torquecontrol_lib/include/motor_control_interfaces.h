/*
 * motor_control_interfaces.h
 *
 *  Created on: Aug 2, 2016
 *      Author: ramin
 */


#ifndef MOTOR_CONTROL_INTERFACES_H_
#define MOTOR_CONTROL_INTERFACES_H_

#include <motor_control_structures.h>

interface BrakeInterface {
    void set_brake(int enable);
    int get_brake();
};

/**
 * @brief Interface type to communicate with the Motor Control Service.
 */
interface MotorcontrolInterface{

    /**
     * @brief Notifies the interested parties that a new notification
     * is available.
     */
    [[notification]]
    slave void notification();

    /**
     * @brief Provides the type of notification currently available.
     *
     * @return type of the notification
     */
    [[clears_notification]]
    int get_notification();


    /**
     * @brief Sets brake status to ON (no movement) or OFF (possible to move)
     */
    void set_brake_status(int brake_status);

    /**
     * @brief Enables the torque control
     */
    void set_torque_control_enabled();

    /**
     * @brief Disables the torque control
     */
    void set_torque_control_disabled();

    /**
     * @brief Enables the offset detection process
     */
    void set_offset_detection_enabled();

    /**
     * @brief Enables the safe-torque-off mode
     */
    void set_safe_torque_off_enabled();

    /**
     * @brief Shows if sensor polarity is true or wrong.
     * If the returned value is 0, then sensor polarity is wrong (sensor polarity should be changed, or motor phases should be flipped)
     * If the returned value is 1, then sensor polarity is true.
     */
    int get_sensor_polarity_state();

    /**
     * @brief Sets offset value
     */
    void set_offset_value(int offset_value);

    /**
     * @brief Sets an amplitude voltage on the sinusodial signals commutating the windings or Q value when FOC is used.
     *
     * @param voltage Voltage [-PWM_MAX_VALUE:PWM_MAX_VALUE]. By default PWM_MAX_VALUE = 13889. In case of FOC [-4096:4096]
     */
    void set_voltage(int voltage);

    /**
     * @brief Sets torque target value when FOC is used.
     *
     * @param torque_sp Torque [-4096:4096].
     */
    void set_torque(int torque_sp);

    /**
     * @brief Sets maximum torque control value when FOC is used.
     *
     * @param torque_sp Torque [-4096:4096].
     */
    void set_torque_max(int torque_sp);

    /**
     * @brief Setter for the configuration used by the Service.
     *        Note that not all configuration parameters can be changed on runtime.
     *
     * @param in_config New Service configuration.
     */
    void set_config(MotorcontrolConfig in_config);

    /**
     * @brief Getter for current configuration used by the Service.
     *
     * @return Current configuration.
     */
    MotorcontrolConfig get_config();

    /**
     * @brief Setter for the status of the FETs
     *
     * @return 0 - FETs disabled.
     *         1 - FETs enabled.
     */
    void set_fets_state(int state);

    /**
     * @brief Getter for the status of the FETs
     *
     * @return 0 - FETs disabled.
     *         1 - FETs enabled.
     */
    int get_fets_state();

    /**
     * @brief Getter for actual torque.
     *
     * @return Torque actual.
     */
    int get_torque_actual();

    /**
     * @brief Getter for actual velocity.
     *
     * @return Velocity actual.
     */
    int get_velocity_actual();

    /**
     * @brief Getter for actual position.
     *
     * @return Position actual.
     */
    int get_position_actual();

    /**
     * @brief Allows you to change the commutation sensor on runtime.
     *
     * @param sensor New sensor [HALL_SENSOR]. (So far, just Hall sensor is available for commutation)
     */
    void set_sensor(int sensor);

    /**
     * @brief Getter for the current state of the Service.
     *
     * @return 0 - not initialized, 1 - initialized.
     */
    int check_busy();

    /**
     * @brief Set calib flag in the Motorcontrol service so it will alway set 0 as electrical angle
     *
     * @param flag 1 to activate, 0 to deactivate calibration
     */
    int set_calib(int flag);

    /**
     * @brief Set the sensor offset of the current position sensor
     *
     * @param Sensor offset
     */
    int set_sensor_offset(int in_offset);

    void set_control(int flag);

    {int, int, int} set_torque_pid(int Kp, int Ki, int Kd);

    void restart_watchdog();

    /**
     * @brief resets the state of motor controller from faulty to normal so that
     *        the application can again be restarted.
     */
    void reset_faults();

    int get_field();

    UpstreamControlData update_upstream_control_data ();
};


/**
 * @brief Interface type to communicate with the ADC Service.
 */
interface ADCInterface{

    /**
     * @brief Get all measured parameters at once
     * The parameters include:
     *  - Current on Phase B
     *  - Current on Phase C
     *  - Vdc
     *  - Torque
     *  - fault code
     */
    {int, int, int, int, int} get_all_measurements();


    // *Max adc ticks are 8192 and corresponds with the max current your DC can handle:
    // DC100: 5A, DC300: 20A, DC1K 50A
    /**
     * @brief Get the ongoing current at B and C Phases.
     *
     * @return Current on B Phase [-8191:8192]. (8192 is equivalent to the max current your SOMANET IFM DC device can handle: DC100: 5A, DC300: 20A, DC1K 50A).
     * @return Current on C Phase [-8191:8192]. (8192 is equivalent to the max current your SOMANET IFM DC device can handle: DC100: 5A, DC300: 20A, DC1K 50A).
     */
    {int, int} get_currents();

    /**
     * @brief Get the value from the temperature sensor on your SOMANET device.
     *        The translation of this value into degrees will depend on your SOMANET device.
     *
     * @return Temperature [0:16383].
     */
    int get_temperature();

    /**
     * @brief Get the voltage value present at the external analog inputs of your SOMANET device.
     *
     * @return Voltage at analog input 1 [0:16384].
     * @return Voltage at analog input 2 [0:16384].
     */
    {int, int} get_external_inputs();

    /**
     * @brief Helper to convert Amps into a suitable ADC value for your SOMANET device.
     *        The output of this helper would be suitable, for instance, as target torque
     *        for a Torque Control Service.
     *
     * @return amps Ampers to convert [A]
     */
    int helper_amps_to_ticks(float amps);

    /**
     * @brief Helper to convert an ADC current value into Amps.
     *
     * @param ticks ADC current value [-8191:8192].
     * @return Amps [A].
     */
    float helper_ticks_to_amps(int ticks);

    /**
     * @brief Enable overcurrent protection.
     *
     */
    void enable_overcurrent_protection();

    /**
     * @brief Get status if overcurrent protection was triggered.
     *
     * @return status [0/1]
     */
    int get_overcurrent_protection_status();

    /**
     * @brief Sets the protection limits including:
     *      - I_max
     *      - V_dc_max
     *      - V_dc_min
     */
    void set_protection_limits(int i_max, int i_ratio, int v_dc_max, int v_dc_min);

    /**
     * @brief Resets the fault state in adc service
     */
    void reset_faults();
};

interface shared_memory_interface {
    /**
    * @brief Getter for electrical angle and current velocity and position.
    *
    * @return  Electrical angle.
    * @return  Current velocity.
    * @return  Current multiturn count.
    */
    {unsigned int, int, int} get_angle_velocity_position();

    /**
    * @brief Getter for electrical angle and current velocity.
    *
    * @return  Electrical angle.
    */
    unsigned int get_angle();

    /**
    * @brief Getter for single-turn position.
    *
    * @return  Single-turn position in ticks.
    */
    unsigned get_position_singleturn();

    /**
    * @brief Getter for multi-turn position.
    *
    * @return  Multi-turn count.
    * @return  Single-turn position in ticks.
    */
    {int, unsigned} get_position_multiturn();

    /**
    * @brief Write electrical angle to shared memory.
    *
    * @param Electrical angle.
    */
    void write_angle_electrical(int);

    /**
    * @brief Write current velocity to shared memory.
    *
    * @param Current velocity.
    */
    void write_current_velocity(int);

    /**
    * @brief Write single-turn position to shared memory.
    *
    * @param  Single-turn position in ticks.
    */
    void write_position_singleturn(unsigned);

    /**
    * @brief Write multi-turn position to shared memory.
    *
    * @param  Multi-turn count.
    * @param  Single-turn position in ticks.
    */
    void write_position_multiturn(int, unsigned);

    /**
    * @brief Write multi-turn electrical angle and current velocity and position to shared memory.
    *
    * @param  Electrical angle.
    * @param  Current velocity.
    * @param  Multi-turn count.
    */
    void write_angle_velocity_position(unsigned int in_angle, int in_velocity, int in_count);

    /**
    * @brief Write multi-turn electrical angle and current velocity and position to shared memory.
    *
    * @param  Current velocity.
    * @param  Multi-turn count.
    */
    void write_velocity_position(int in_velocity, int in_count);

};

interface update_pwm
{
    void update_server_control_data(int pwm_a, int pwm_b, int pwm_c, int pwm_on, int brake_active, int recieved_safe_torque_off_mode);
    void safe_torque_off_enabled();
};


/**
 * @brief Interface type to communicate with the Watchdog Service.
 */
interface WatchdogInterface{

    /**
     * @brief Initialize and starts ticking the watchdog.
     */
    void start(void);

    /**
     * @brief Stops ticking the watchdog. Therefore, any output through the phases is disabled.
     */
    void stop(void);

    /**
     * @reacts on any detected fault. Any output through the phases will be disabled.
     */
    void protect(int fault_id);

    /**
     * @resets the state of fault in watchdog service, and starts the watchdog from the beginning
     */
    void reset_faults();
};

#endif /* MOTOR_CONTROL_INTERFACES_H_ */
