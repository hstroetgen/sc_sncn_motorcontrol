/**
 * @file  motion_control_service.h
 * @brief Position Control Loop Server Implementation
 * @author Synapticon GmbH <support@synapticon.com>
*/

#pragma once

#include <motor_control_interfaces.h>
#include <advanced_motor_control.h>

/**
 * @brief Denominator for PID contants. The values set by the user for such constants will be divided by this value (10000 by default).
 */
#define PID_DENOMINATOR 10000.0

/**
 * @brief threshold in ticks to re-enable the position controler if the limit reached.
 */
#define POSITION_LIMIT_THRESHOLD        20000

/**
 * @brief Period for the control loop [microseconds].
 */
#define POSITION_CONTROL_LOOP_PERIOD    1000


/**
 * @brief Position/Velocity control strategie
 */
typedef enum {
    POS_PID_CONTROLLER                      = 101,
    POS_PID_VELOCITY_CASCADED_CONTROLLER    = 102,
    NL_POSITION_CONTROLLER                  = 103,
    VELOCITY_PID_CONTROLLER                 = 201
} MotionControlStrategies;


/**
 * @brief Motion polarity
 *
 *  When set to INVERTED (1) the position/velocity/torque commands will be inverted.
 *  The position/velocity/torque feedback is also inverted to match the commands.
 *  The position limits are also inverted to match the inverted position commands.
 *  The internal position of the controller is not changed, only the feedback.
 */
typedef enum {
    MOTION_POLARITY_NORMAL      = 0,
    MOTION_POLARITY_INVERTED    = 1
} MotionPolarity;

/**
 * @brief Structure definition for a Control Loop Service configuration.
 */
typedef struct {
    int Kp_n; /**< Value for proportional coefficient (Kp) in PID controller. Kp = Kp_n/PID_DENOMINATOR (by default PID_DENOMINATOR = 10000) */
    int Ki_n; /**< Value for integral coefficient (Ki) in PID controller. Ki = Ki_n/PID_DENOMINATOR (by default PID_DENOMINATOR = 10000) */
    int Kd_n; /**< Value for differential coefficient (Kd) in PID controller. Kd = Kd_n/PID_DENOMINATOR (by default PID_DENOMINATOR = 10000) */
    int control_loop_period; /**< Period for the control loop [microseconds]. */
    int feedback_sensor; /**< Sensor used for position control feedback [HALL_SENSOR, QEI_SENSOR]*/
    int cascade_with_torque; /**< Add torque controller at the end of velocity controller (only possible with FOC) [0, 1]*/
} ControlConfig;

/**
 * @brief Structure definition for a Control Loop Service configuration.
 */
typedef struct {

    int position_control_strategy;      /**< Value for selecting between defferent types of position controllers or velocity controller. */
    int motion_profile_type;            /**< Value for selecting between different types of profilers (including torque/velocity/posiiton controllers. */

    int min_pos_range_limit;            /**< Value for setting the minimum position range */
    int max_pos_range_limit;            /**< Value for setting the maximum position range */
    int max_motor_speed;                /**< Value for setting the maximum motor speed */
    int max_torque;                     /**< Value for setting the maximum torque command which will be sent to torque controller */

    int enable_profiler;                /**< Value for enabling/disabling the profiler */
    int max_acceleration_profiler;      /**< Value for setting the maximum acceleration in profiler mode */
    int max_speed_profiler;             /**< Value for setting the maximum speed in profiler mode */
    int max_torque_rate_profiler;       /**< Value for setting the maximum torque in profiler mode */

    int position_kp;                    /**< Value for position controller p-constant */
    int position_ki;                    /**< Value for position controller i-constant */
    int position_kd;                    /**< Value for position controller d-constant */
    int position_integral_limit;        /**< Value for integral limit of position pid controller */

    int velocity_kp;                    /**< Value for velocity controller p-constant */
    int velocity_ki;                    /**< Value for velocity controller i-constant */
    int velocity_kd;                    /**< Value for velocity controller d-constant */
    int velocity_integral_limit;        /**< Value for integral limit of velocity pid controller */

    int k_fb;                           /**< Value for setting the feedback position sensor gain */
    int resolution;                     /**< Value for setting the resolution of position sensor [ticks/rotation] */
    int k_m;                            /**< Value for setting the gain of torque actuator */
    int moment_of_inertia;              /**< Value for setting the moment of inertia */
    MotionPolarity polarity;            /**< Value for setting the polarity of the movement */
    int brake_release_strategy;
    int brake_shutdown_delay;

    int dc_bus_voltage;                 /**< Value for setting the nominal (rated) value of dc-link */
    int pull_brake_voltage;             /**< Value for setting the voltage for pulling the brake out! */
    int pull_brake_time;                /**< Value for setting the time of brake pulling */
    int hold_brake_voltage;             /**< Value for setting the brake voltage after it is pulled */
} MotionControlConfig;

/**
 * @brief Interface type to communicate with the Motion Control Service.
 */
interface PositionVelocityCtrlInterface
{

    /**
     * @brief disables the motion control service
     */
    void disable();

    /**
     * @brief enables the position controler
     *
     * @param mode-> position control mode
     */
    void enable_position_ctrl(int mode);

    /**
     * @brief enables the velocity controller
     */
    void enable_velocity_ctrl(void);

    /**
     * @brief sets the moment of inertia of the load
     *
     * @param j-> moment of intertia
     */
    void set_j(int j);

    /**
     * @brief enables the torque controller
     */
    void enable_torque_ctrl();

    /**
     * @brief sets the reference value of torque in torque control mode
     *
     * @param target_torque -> torque reference in mNm
     */
    void set_torque(int target_torque);

    /**
     * @brief Getter for current configuration used by the Service.
     *
     * @return Current Service configuration.
     */
    MotionControlConfig get_position_velocity_control_config();

    /**
     * @brief Setter for new configuration in the Service.
     *
     * @param in_config New Service configuration.
     */
    void set_position_velocity_control_config(MotionControlConfig in_config);

    /**
     * @brief Setter for new configuration in the Motorcontrol Service.
     *
     * @param in_config New Service configuration.
     */
    void set_motorcontrol_config(MotorcontrolConfig in_config);

    /**
     * @brief Getter for current configuration used by the Motorcontrol Service.
     *
     * @return Current Service configuration.
     */
    MotorcontrolConfig get_motorcontrol_config();

    /**
     * @brief Sets brake status to ON (no movement) or OFF (possible to move)
     *
     * @param brake_status -> release if 1, block if 0
     */
    void set_brake_status(int brake_status);

    /**
     * @brief updates the new brake configuration in pwm service
     */
    void update_brake_configuration();

    /**
     * @brief Enables the offset detection process
     */
    MotorcontrolConfig set_offset_detection_enabled();

    /**
     * @brief Send a reset fault command to the motorcontrol
     */
    void reset_motorcontrol_faults();

    /**
     * @brief getter of actual position
     */
    int get_position();

    /**
     * @brief getter of actual velocity
     */
    int get_velocity();

    /**
     * @brief responsible for data communication between torque controller and higher level controllers
     *
     * @param downstreamcontroldata -> structure including the commands for torque/velocity/position controller
     *
     * @return structure of type UpstreamControlData -> structure including the actual parameters (measurements, ...) from torque controller to higher controlling levels
     */
    UpstreamControlData update_control_data(DownstreamControlData downstreamcontroldata);
};


/**
 * @brief Initializer helper for the Position Control Service.
 *        It is required the client to call this function before
 *        starting to perform position control.
 *
 * @param i_position_control Communication interface to the Position Control Service.
 *
 * @return void
 */
void init_position_velocity_control(interface PositionVelocityCtrlInterface client i_position_control);

/**
 * @brief Service to perform torque, velocity or position control.
 *        You will need a Motor Control Stack running parallel to this Service,
 *        have a look at Motor Control Service for more information.
 *
 *  Note: It is important to allocate this service in a different tile from the remaining Motor Control stack.
 *
 * @param pos_velocity_control_config   Configuration for ttorque/velocity/position controllers.
 * @param i_motorcontrol Communication  interface to the Motor Control Service.
 * @param i_position_control[3]         array of PositionVelocityCtrlInterfaces to communicate with upto 3 clients
 * @param i_update_brake                Interface to update brake configuration in PWM service
 *
 * @return void
 *  */
void motion_control_service(int app_tile_usec, MotionControlConfig &pos_velocity_control_config,
                    interface MotorControlInterface client i_motorcontrol,
                    interface PositionVelocityCtrlInterface server i_position_control[3],
                    client interface UpdateBrake i_update_brake);
