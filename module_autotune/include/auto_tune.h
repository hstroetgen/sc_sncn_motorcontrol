/**
 * @file auto_tune.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once
#include <motion_control_service.h>

/**
 * @brief The velocity in which the tuning will happen. (suggested value: 60% of rated velocity).
 *        Note: The dc-bus voltage should be high enough for the selected velocity.
 */
#define TUNING_VELOCITY 1000 //[rpm]

#define SETTLING_TIME   0.3  //preffered settling time for velocity controller [seconds]

/**
 * @brief Structure type containing auto_tuning parameters of velocity/position controllers
 */
typedef struct {
    int enable;                     //flag for enable/disable auto tuner
    int counter;                    // position feedback gain
    int save_counter;               // counter for saving the speed values
    double velocity_ref;            // reference of velocity in [rpm]
    int array_length;               // length of measurement array
    int  actual_velocity[1001];     // array containing measured actual velocity
    double j;                       // moment of inertia
    double f;                       // friction factor
    double z;
    double st;

    double kp;
    double ki;
    double kd;
} VelCtrlAutoTuneParam;


/**
 * @brief Initializes the structure of type VelCtrlAutoTuneParam to start the auto tuning procedure.
 *
 * @param velocity_auto_tune    structure of type VelCtrlAutoTuneParam which contains velocity_auto_tuning parameters
 * @param velocity_ref          The reference velocity which will be used in auto_tuning procedure.
 *                              Note: velocity_ref should be between 50% to 100% of the rated velocity. Moreover, the supply voltage should be at its nominal value while auto_tuning is in progress.
 *
 * @return int                  the function returns 0 by default
 *  */
int init_velocity_auto_tuner(VelCtrlAutoTuneParam &velocity_auto_tune, int velocity_ref, double settling_time);


/**
 * @brief Executes the auto tuning procedure for a PID velocity controller. The results of this procedure will be the PID constants for velocity controller.
 *
 * @param velocity_auto_tune    structure of type VelCtrlAutoTuneParam which contains velocity_auto_tuning parameters
 * @param velocity_ref_in_k     The reference velocity which will be used in auto_tuning procedure.
 * @param velocity_k            Actual velocity of motor (in rpm) which is measured by position feedback service
 * @param period                Velocity control execution period (in micro-seconds).

 * @return int                  the function returns 0 by default
 *  */
int velocity_controller_auto_tune(VelCtrlAutoTuneParam &velocity_auto_tune,MotionControlConfig &motion_ctrl_config, double &velocity_ref_in_k, double velocity_k, int period);


// position controller autotuner
#define AUTO_TUNE_STEP_AMPLITUDE    20000 // The tuning procedure uses steps to evaluate the response of controller. This input is equal to half of step command amplitude.
#define AUTO_TUNE_COUNTER_MAX       1500  // The period of step commands in ticks. Each tick is corresponding to one execution sycle of motion_control_service. As a result, 3000 ticks when the frequency of motion_control_service is 1 ms leads to a period equal to 3 seconds for each step command.
#define PER_THOUSAND_OVERSHOOT      10    // Overshoot limit while tuning (it is set as per thousand of step amplitude)

/**
 * @brief different steps of autotuning function
 */
typedef enum {
    SIMPLE_PID=1,
    CASCADED=2,
    LIMITED_TORQUE=3,

    AUTO_TUNE_STEP_1=11,
    AUTO_TUNE_STEP_2=12,
    AUTO_TUNE_STEP_3=13,
    AUTO_TUNE_STEP_4=14,
    AUTO_TUNE_STEP_5=15,
    AUTO_TUNE_STEP_6=16,
    AUTO_TUNE_STEP_7=17,
    AUTO_TUNE_STEP_8=18,
    AUTO_TUNE_STEP_9=19,

    END=50
} AutotuneSteps;

/**
 * @brief Structure type containing auto_tuning parameters
 */
typedef struct {

    int controller;
    double position_init;
    double position_ref;
    int rising_edge;

    int activate;
    int counter;
    int counter_max;

    int active_step_counter;
    int active_step;

    int kvp;
    int kvi;
    int kvd;
    int kvl;

    int kpp;
    int kpi;
    int kpd;
    int kpl;
    int j;

    int auto_tune;

    double step_amplitude;

    double err;
    double err_energy;
    double err_energy_int;
    double err_energy_int_max;

    double err_ss;
    double err_energy_ss;
    double err_energy_ss_int;
    double err_energy_ss_int_min;
    double err_energy_ss_limit_soft;

    double overshoot;
    double overshoot_max;

    int tuning_process_ended;

} PosCtrlAutoTuneParam;


/**
 * @brief function to initialize the structure of automatic tuner for limited torque position controller.
 *
 * @param pos_ctrl_auto_tune         structure of type PosCtrlAutoTuneParam which will be used during the tuning procedure
 * @param step_amplitude Communication  The tuning procedure uses steps to evaluate the response of controller. This input is equal to half of step command amplitude.
 * @param counter_max                   The period of step commands in ticks. Each tick is corresponding to one execution sycle of motion_control_service. As a result, 3000 ticks when the frequency of motion_control_service is 1 ms leads to a period equal to 3 seconds for each step command.
 * @param overshot_per_thousand         Overshoot limit while tuning (it is set as per thousand of step amplitude)
 * @param rise_time_freedom_percent     This value helps the tuner to find out whether the ki is high enough or not. By default set this value to 300, and if the tuner is not able to find proper values (and the response is having oscillations), increase this value to 400 or 500.
 *
 * @return void
 *  */
int init_pos_ctrl_autotune(PosCtrlAutoTuneParam &pos_ctrl_auto_tune, MotionControlConfig &motion_ctrl_config, int controller_type);

/**
 * @brief function to automatically tune the limited torque position controller.
 *
 * @param motion_ctrl_config            Structure containing all parameters of motion control service
 * @param pos_ctrl_auto_tune         structure of type PosCtrlAutoTuneParam which will be used during the tuning procedure
 * @param position_k                    The actual position of the system while (double)
 *
 * @return void
 *  */
int pos_ctrl_autotune(PosCtrlAutoTuneParam &pos_ctrl_auto_tune, MotionControlConfig &motion_ctrl_config, double position_k);





