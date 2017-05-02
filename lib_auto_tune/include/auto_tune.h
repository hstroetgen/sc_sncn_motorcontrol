/**
 * @file auto_tune.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

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
} AutoTuneParam;

/**
 * @brief Initializes the structure of type AutoTuneParam to start the auto tuning procedure.
 *
 * @param velocity_auto_tune    structure of type AutoTuneParam which contains velocity_auto_tuning parameters
 * @param velocity_ref          The reference velocity which will be used in auto_tuning procedure.
 *                              Note: velocity_ref should be between 50% to 100% of the rated velocity. Moreover, the supply voltage should be at its nominal value while auto_tuning is in progress.
 *
 * @return int                  the function returns 0 by default
 *  */
int init_velocity_auto_tuner(AutoTuneParam &velocity_auto_tune, int velocity_ref);


/**
 * @brief Executes the auto tuning procedure for a PID velocity controller. The results of this procedure will be the PID constants for velocity controller.
 *
 * @param velocity_auto_tune    structure of type AutoTuneParam which contains velocity_auto_tuning parameters
 * @param velocity_ref_in_k     The reference velocity which will be used in auto_tuning procedure.
 * @param velocity_k            Actual velocity of motor (in rpm) which is measured by position feedback service
 * @param period                Velocity control execution period (in micro-seconds).

 * @return int                  the function returns 0 by default
 *  */
int velocity_controller_auto_tune(AutoTuneParam &velocity_auto_tune, double &velocity_ref_in_k, double velocity_k, int period);
