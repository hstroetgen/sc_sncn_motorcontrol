/**
 * @file auto_tune.xc
 * @brief Controllers Libraries
 * @author Synapticon GmbH <support@synapticon.com>
 */

#include <auto_tune.h>

/**
 * @brief Initializes the structure of type VelCtrlAutoTuneParam to start the auto tuning procedure.
 *
 * @param velocity_auto_tune    structure of type VelCtrlAutoTuneParam which contains velocity_auto_tuning parameters
 * @param velocity_ref          The reference velocity which will be used in auto_tuning procedure.
 *                              Note: velocity_ref should be between 50% to 100% of the rated velocity. Moreover, the supply voltage should be at its nominal value while auto_tuning is in progress.
 * @param settling_time         settling time for automatic tuning of velocity pid controller
 *
 * @return int                  the function returns 0 by default
 *  */
int init_velocity_auto_tuner(VelCtrlAutoTuneParam &velocity_auto_tune, int velocity_ref, double settling_time)
{
    velocity_auto_tune.enable=0;
    velocity_auto_tune.counter=0;
    velocity_auto_tune.save_counter=0;
    velocity_auto_tune.array_length=1000;
    for(int i=1; i<=velocity_auto_tune.array_length; i++) velocity_auto_tune.actual_velocity[i]=0;

    velocity_auto_tune.j = 0.00;
    velocity_auto_tune.f = 0.00;
    velocity_auto_tune.z = 0.70;
    velocity_auto_tune.st= settling_time;

    velocity_auto_tune.kp   = 0.00;
    velocity_auto_tune.ki   = 0.00;
    velocity_auto_tune.kd   = 0.00;

    velocity_auto_tune.velocity_ref = velocity_ref;
    if(velocity_auto_tune.velocity_ref>2000)
        velocity_auto_tune.velocity_ref=2000;//set the maximum value for speed evaluation to 2000 rpm

    return 0;
}

/**
 * @brief Executes the auto tuning procedure for a PID velocity controller. The results of this procedure will be the PID constants for velocity controller.
 *
 * @param velocity_auto_tune    structure of type VelCtrlAutoTuneParam which contains velocity_auto_tuning parameters
 * @param velocity_ref_in_k     The reference velocity which will be used in auto_tuning procedure.
 * @param velocity_k            Actual velocity of motor (in rpm) which is measured by position feedback service
 * @param period                Velocity control execution period (in micro-seconds).

 * @return int                  the function returns 0 by default
 *  */
int velocity_controller_auto_tune(VelCtrlAutoTuneParam &velocity_auto_tune,MotionControlConfig &motion_ctrl_config, double &velocity_ref_in_k, double velocity_k, int period)
{

    double wn_auto_tune   = 0.00;

    double steady_state = 0.00;
    double k = 0.00;
    double g_speed = 0.00;
    double speed_integral = 0.00;
    int    saving_reduction_factor = 4;//reduces the number of saved states

    velocity_auto_tune.save_counter++;
    if(velocity_auto_tune.save_counter==saving_reduction_factor)
    {
        velocity_auto_tune.save_counter=0;
        velocity_auto_tune.counter++;
    }

    if(1<=velocity_auto_tune.counter && velocity_auto_tune.counter<=velocity_auto_tune.array_length)
    {
        velocity_auto_tune.enable = 1;

        velocity_ref_in_k = velocity_auto_tune.velocity_ref;
        velocity_auto_tune.actual_velocity[velocity_auto_tune.counter] = ((int)(velocity_k));

        if(velocity_auto_tune.counter==velocity_auto_tune.array_length)
        {
            steady_state = 0;
            for(int i=(velocity_auto_tune.array_length-100); i<=velocity_auto_tune.array_length; i++)
                steady_state +=  ((double)velocity_auto_tune.actual_velocity[i]);
            steady_state = steady_state/100.00;

            k = (steady_state / velocity_auto_tune.velocity_ref);
            g_speed = 60.00/(2.00*3.1416);

            speed_integral=0.00;
            for(int i=1; i<=velocity_auto_tune.array_length; i++)
                speed_integral += (steady_state-((double)(velocity_auto_tune.actual_velocity[i])));

            speed_integral *= ((saving_reduction_factor*period)/1000000.00);
            speed_integral /= g_speed;

            velocity_auto_tune.j = (speed_integral*0.001);                  //k_m = 0.001
            velocity_auto_tune.j/= (steady_state/g_speed);
            velocity_auto_tune.j/= (steady_state/g_speed);
            velocity_auto_tune.j*= (velocity_auto_tune.velocity_ref);

            velocity_auto_tune.f = (velocity_auto_tune.velocity_ref*0.001);
            velocity_auto_tune.f/= (steady_state/g_speed);
            velocity_auto_tune.f-= (0.001*g_speed);

            if(velocity_auto_tune.f>0 && velocity_auto_tune.j>0)
            {
                wn_auto_tune = 4.00 / (velocity_auto_tune.z * velocity_auto_tune.st);
                velocity_auto_tune.kp = 1.00/(0.001*g_speed);
                velocity_auto_tune.kp*= ((2.00 * velocity_auto_tune.z * wn_auto_tune*velocity_auto_tune.j)-velocity_auto_tune.f);

                velocity_auto_tune.ki = (wn_auto_tune*wn_auto_tune*velocity_auto_tune.j);
                velocity_auto_tune.ki/= (0.001*g_speed);

                velocity_auto_tune.kp *= 1000000.00;
                velocity_auto_tune.ki *= 1000.00;

                if(velocity_auto_tune.kp<0 || velocity_auto_tune.ki<0) //wrong calculation
                {
                    velocity_auto_tune.kp = 00.00;
                    velocity_auto_tune.ki = 00.00;
                }
            }
            else //wrong calculation
            {
                velocity_auto_tune.kp = 00.00;
                velocity_auto_tune.ki = 00.00;
            }
        }
    }
    else if (velocity_auto_tune.counter<=((velocity_auto_tune.array_length*5)/4))//try to reach 0 rpm in 20% of testint time
    {
        velocity_auto_tune.enable = 1;
        velocity_ref_in_k = 0;
    }
    else
    {
        velocity_auto_tune.enable = 0;
        velocity_auto_tune.counter=0;

        motion_ctrl_config.enable_velocity_auto_tuner = 0;
        motion_ctrl_config.velocity_kp = ((int)(velocity_auto_tune.kp));
        motion_ctrl_config.velocity_ki = ((int)(velocity_auto_tune.ki));
        motion_ctrl_config.velocity_kd = ((int)(velocity_auto_tune.kd));

        for(int i=0; i<=velocity_auto_tune.array_length; i++) velocity_auto_tune.actual_velocity[i] = 0;
    }

    return 0;
}



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
int init_pos_ctrl_autotune(PosCtrlAutoTuneParam &pos_ctrl_auto_tune, MotionControlConfig &motion_ctrl_config, int controller_type)
{
    pos_ctrl_auto_tune.controller = controller_type;

    pos_ctrl_auto_tune.position_init = 0.00;
    pos_ctrl_auto_tune.position_ref  = 0.00;
    pos_ctrl_auto_tune.auto_tune  = 0;

    pos_ctrl_auto_tune.activate=0;
    pos_ctrl_auto_tune.counter=0;
    pos_ctrl_auto_tune.counter_max=motion_ctrl_config.counter_max_autotune;

    pos_ctrl_auto_tune.step_amplitude = motion_ctrl_config.step_amplitude_autotune;
//    if(pos_ctrl_auto_tune.controller==CASCADED)
//        pos_ctrl_auto_tune.step_amplitude /=4;

    pos_ctrl_auto_tune.err=0.00;
    pos_ctrl_auto_tune.err_energy=0.00;
    pos_ctrl_auto_tune.err_energy_int    =0.00;
    pos_ctrl_auto_tune.err_energy_int_max    = ((2*pos_ctrl_auto_tune.step_amplitude)/1000) * ((2*pos_ctrl_auto_tune.step_amplitude)/1000) * pos_ctrl_auto_tune.counter_max;

    pos_ctrl_auto_tune.err_ss=0.00;
    pos_ctrl_auto_tune.err_energy_ss=0.00;
    pos_ctrl_auto_tune.err_energy_ss_int=0.00;
    //steady state error is measured between 90% and 98% of the period, and its min value is when real position is having a margin of 0.01 with reference position
    pos_ctrl_auto_tune.err_energy_ss_limit_soft = (((pos_ctrl_auto_tune.step_amplitude)/100) * ((pos_ctrl_auto_tune.step_amplitude)/100) * pos_ctrl_auto_tune.counter_max * 8.00) /100.00;
    pos_ctrl_auto_tune.err_energy_ss_int_min    = pos_ctrl_auto_tune.err_energy_ss_limit_soft;

    pos_ctrl_auto_tune.active_step_counter=0;
    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_1;

    pos_ctrl_auto_tune.rising_edge=0;

    pos_ctrl_auto_tune.overshoot=0.00;
    pos_ctrl_auto_tune.overshoot_max=0.00;

    pos_ctrl_auto_tune.tuning_process_ended=0;

    return 0;
}


/**
 * @brief function to automatically tune the limited torque position controller.
 *
 * @param pos_ctrl_auto_tune            Structure containing all parameters of motion control service
 * @param pos_ctrl_auto_tune         structure of type PosCtrlAutoTuneParam which will be used during the tuning procedure
 * @param position_k                    The actual position of the system while (double)
 *
 * @return void
 *  */
int pos_ctrl_autotune(PosCtrlAutoTuneParam &pos_ctrl_auto_tune, MotionControlConfig &motion_ctrl_config, double position_k)
{

    pos_ctrl_auto_tune.auto_tune =  motion_ctrl_config.position_control_autotune;

    pos_ctrl_auto_tune.counter++;

    if(pos_ctrl_auto_tune.controller == CASCADED)
    {
        if(pos_ctrl_auto_tune.activate==0)
        {
            pos_ctrl_auto_tune.position_init = position_k;

            pos_ctrl_auto_tune.kpp = 0 ;
            pos_ctrl_auto_tune.kpi = 0 ;
            pos_ctrl_auto_tune.kpd = 0 ;
            pos_ctrl_auto_tune.kpl = 10000000;
            pos_ctrl_auto_tune.j  = 0;

            pos_ctrl_auto_tune.kvp = 0 ;
            pos_ctrl_auto_tune.kvi = 0 ;
            pos_ctrl_auto_tune.kvd = 0 ;
            pos_ctrl_auto_tune.kvl = 10000000;

            pos_ctrl_auto_tune.activate = 1;
            pos_ctrl_auto_tune.counter=0;

            pos_ctrl_auto_tune.counter_max=pos_ctrl_auto_tune.counter_max/3;
        }

        if(pos_ctrl_auto_tune.counter==pos_ctrl_auto_tune.counter_max)
        {
            //change of reference value in each cycle
            if(pos_ctrl_auto_tune.position_ref == (pos_ctrl_auto_tune.position_init + pos_ctrl_auto_tune.step_amplitude))
            {
                pos_ctrl_auto_tune.position_ref = pos_ctrl_auto_tune.position_init - pos_ctrl_auto_tune.step_amplitude;
                pos_ctrl_auto_tune.rising_edge=0;
            }
            else
            {
                pos_ctrl_auto_tune.position_ref = pos_ctrl_auto_tune.position_init + pos_ctrl_auto_tune.step_amplitude;
                pos_ctrl_auto_tune.rising_edge=1;
            }

            // force the load to follow the reference value
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_1)//step 1
            {
                if(pos_ctrl_auto_tune.err_energy_int < (pos_ctrl_auto_tune.err_energy_int_max/10))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    if(pos_ctrl_auto_tune.active_step_counter==0)
                        pos_ctrl_auto_tune.kvp += 50000;
                    else
                        pos_ctrl_auto_tune.kvp += 10000;

                        pos_ctrl_auto_tune.kpp = pos_ctrl_auto_tune.kvp/10;

                    pos_ctrl_auto_tune.active_step_counter=0;
                }

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_2;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }

                if(pos_ctrl_auto_tune.err_energy_ss_int>pos_ctrl_auto_tune.err_energy_ss_int_min)
                    pos_ctrl_auto_tune.err_energy_ss_int_min = (pos_ctrl_auto_tune.err_energy_ss_int_min+pos_ctrl_auto_tune.err_energy_ss_int)/2;
            }


            //increase kvp until it starts to vibrate or overshoot > 2%
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_2)// step 2
            {
                if(pos_ctrl_auto_tune.err_energy_ss_int < (5*pos_ctrl_auto_tune.err_energy_ss_int_min) && pos_ctrl_auto_tune.overshoot_max<((20*pos_ctrl_auto_tune.step_amplitude)/1000))
                {
                    pos_ctrl_auto_tune.kvp = (pos_ctrl_auto_tune.kvp*1005)/1000;
                    pos_ctrl_auto_tune.kvi = pos_ctrl_auto_tune.kvp/10000;

                    pos_ctrl_auto_tune.kpp = pos_ctrl_auto_tune.kvp/10;
                    pos_ctrl_auto_tune.kpi = pos_ctrl_auto_tune.kpp/10000;
                }
                else
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }

                if(100<pos_ctrl_auto_tune.err_energy_ss_int && pos_ctrl_auto_tune.err_energy_ss_int<pos_ctrl_auto_tune.err_energy_ss_int_min)
                    pos_ctrl_auto_tune.err_energy_ss_int_min = (2*pos_ctrl_auto_tune.err_energy_ss_int+pos_ctrl_auto_tune.err_energy_ss_int_min)/3;


                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_3;

                    pos_ctrl_auto_tune.kvp=(pos_ctrl_auto_tune.kvp*90)/100;
                    pos_ctrl_auto_tune.kvi = pos_ctrl_auto_tune.kvp/10000;
                    pos_ctrl_auto_tune.kpp = pos_ctrl_auto_tune.kvp/10;
                    pos_ctrl_auto_tune.kpi = pos_ctrl_auto_tune.kpp/10000;

                    pos_ctrl_auto_tune.counter_max=pos_ctrl_auto_tune.counter_max*3;

                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            //increase kvi until overshoot is less than 1%
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_3)//step 3
            {
                if(pos_ctrl_auto_tune.overshoot_max>((10*pos_ctrl_auto_tune.step_amplitude)/1000))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    pos_ctrl_auto_tune.kvi = (pos_ctrl_auto_tune.kvi*110)/100;
                }

                if(pos_ctrl_auto_tune.err_energy_ss_int>pos_ctrl_auto_tune.err_energy_ss_int_min)
                         pos_ctrl_auto_tune.err_energy_ss_int_min = (pos_ctrl_auto_tune.err_energy_ss_int_min+pos_ctrl_auto_tune.err_energy_ss_int)/2;

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_4;
                    pos_ctrl_auto_tune.kvi = (pos_ctrl_auto_tune.kvi*90)/100;

                    pos_ctrl_auto_tune.counter_max/=3;
                    pos_ctrl_auto_tune.err_energy_ss_int_min/=3;

                    pos_ctrl_auto_tune.kvl = 100000;

                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            //reduce kvl until overshoot is less than 2%
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_4)//step 3.5
            {
                if(pos_ctrl_auto_tune.overshoot_max<((30*pos_ctrl_auto_tune.step_amplitude)/1000))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    pos_ctrl_auto_tune.kvl = (pos_ctrl_auto_tune.kvl*90)/100;
                }


                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_5;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            //increase kpp until it starts to vibrate
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_5)// step 4
            {
                if(pos_ctrl_auto_tune.err_energy_ss_int < (2*pos_ctrl_auto_tune.err_energy_ss_int_min))
                {
                    pos_ctrl_auto_tune.kpp = (pos_ctrl_auto_tune.kpp*1010)/1000;
                    if(pos_ctrl_auto_tune.kpp<100) pos_ctrl_auto_tune.kpp =100;
                }
                else
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }

                if(pos_ctrl_auto_tune.err_energy_ss_int<pos_ctrl_auto_tune.err_energy_ss_int_min)
                    pos_ctrl_auto_tune.err_energy_ss_int_min = (2*pos_ctrl_auto_tune.err_energy_ss_int+pos_ctrl_auto_tune.err_energy_ss_int_min)/3;


                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_6;

                    pos_ctrl_auto_tune.kpp = (pos_ctrl_auto_tune.kpp*90)/100;

                    pos_ctrl_auto_tune.counter_max*=3;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            //increase kpi until overshoot is more than 10%
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_6)//step 5
            {
                if(pos_ctrl_auto_tune.overshoot_max>((100*pos_ctrl_auto_tune.step_amplitude)/1000))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    pos_ctrl_auto_tune.kpi = (pos_ctrl_auto_tune.kpi*110)/100;
                    if(pos_ctrl_auto_tune.kpi<10) pos_ctrl_auto_tune.kpi=10;
                }


                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_7;
                    pos_ctrl_auto_tune.kpi = (pos_ctrl_auto_tune.kpi*90)/100;
                    pos_ctrl_auto_tune.kpl = 10000;
                    pos_ctrl_auto_tune.active_step_counter=0;

                }
            }

            //reduce kpl until overshoot is less than 5%
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_7)//step 6
            {
                if(pos_ctrl_auto_tune.overshoot_max<((50*pos_ctrl_auto_tune.step_amplitude)/1000))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    pos_ctrl_auto_tune.kpl = (pos_ctrl_auto_tune.kpl*95)/100;
                }


                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_8;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            //increase kpi until err_ss is low enough
            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_8)//step 5
            {
                if(pos_ctrl_auto_tune.err_energy_ss_int < (100*100*8*pos_ctrl_auto_tune.counter_max)/100)
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    pos_ctrl_auto_tune.kpi = (pos_ctrl_auto_tune.kpi*110)/100;
                }

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=END;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            //end the application
            if(pos_ctrl_auto_tune.active_step==END)//step 7
            {
                pos_ctrl_auto_tune.tuning_process_ended=1;
                pos_ctrl_auto_tune.auto_tune = 0;
                pos_ctrl_auto_tune.activate=0;


                pos_ctrl_auto_tune.active_step_counter=0;
            }


            if(pos_ctrl_auto_tune.rising_edge==1)
            {
                pos_ctrl_auto_tune.overshoot=0;
                pos_ctrl_auto_tune.overshoot_max=0;
            }

            pos_ctrl_auto_tune.err=0.00;
            pos_ctrl_auto_tune.err_energy =0.00;
            pos_ctrl_auto_tune.err_energy_int=0.00;

            pos_ctrl_auto_tune.err_ss=0.00;
            pos_ctrl_auto_tune.err_energy_ss =0.00;
            pos_ctrl_auto_tune.err_energy_ss_int = 0.00;

            pos_ctrl_auto_tune.counter=0;
        }
    }
    else if(pos_ctrl_auto_tune.controller == LIMITED_TORQUE)
    {
        if(pos_ctrl_auto_tune.activate==0)
        {
            pos_ctrl_auto_tune.position_init = position_k;

            pos_ctrl_auto_tune.kpp = 10000 ;
            pos_ctrl_auto_tune.kpi = 1000  ;
            pos_ctrl_auto_tune.kpd = 40000 ;
            pos_ctrl_auto_tune.kpl = 1;
            pos_ctrl_auto_tune.j  = 0;

            pos_ctrl_auto_tune.activate = 1;
            pos_ctrl_auto_tune.counter=0;
        }

        if(pos_ctrl_auto_tune.counter==pos_ctrl_auto_tune.counter_max)
        {
            //change of reference value in each cycle
            if(pos_ctrl_auto_tune.position_ref == (pos_ctrl_auto_tune.position_init + pos_ctrl_auto_tune.step_amplitude))
            {
                pos_ctrl_auto_tune.position_ref = pos_ctrl_auto_tune.position_init - pos_ctrl_auto_tune.step_amplitude;
                pos_ctrl_auto_tune.rising_edge=0;
            }
            else
            {
                pos_ctrl_auto_tune.position_ref = pos_ctrl_auto_tune.position_init + pos_ctrl_auto_tune.step_amplitude;
                pos_ctrl_auto_tune.rising_edge=1;
            }

            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_1)//step 1
            {
                if(pos_ctrl_auto_tune.err_energy_int < (pos_ctrl_auto_tune.err_energy_int_max/10))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    pos_ctrl_auto_tune.kpl += 50;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_2;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_2)//step 2
            {
                if(pos_ctrl_auto_tune.overshoot_max<((100*pos_ctrl_auto_tune.step_amplitude)/1000) && pos_ctrl_auto_tune.err_energy_ss_int<pos_ctrl_auto_tune.err_energy_ss_limit_soft)
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    if(pos_ctrl_auto_tune.tuning_process_ended==0)
                        pos_ctrl_auto_tune.kpi = (pos_ctrl_auto_tune.kpi*100)/120;

                    if(pos_ctrl_auto_tune.kpi<10 && pos_ctrl_auto_tune.tuning_process_ended==0)
                        pos_ctrl_auto_tune.kpi = 10;

                    pos_ctrl_auto_tune.active_step_counter=0;
                }

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_3;
                    pos_ctrl_auto_tune.active_step_counter=0;

                }

            }

            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_3)// step 3
            {
                if(pos_ctrl_auto_tune.err_energy_ss_int < 10*pos_ctrl_auto_tune.err_energy_ss_int_min)
                {
                    pos_ctrl_auto_tune.kpl+=100;
                }
                else
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }

                if(pos_ctrl_auto_tune.err_energy_ss_int<pos_ctrl_auto_tune.err_energy_ss_int_min)
                    pos_ctrl_auto_tune.err_energy_ss_int_min = (pos_ctrl_auto_tune.err_energy_ss_int+(3.00*pos_ctrl_auto_tune.err_energy_ss_int_min))/4;


                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_4;
                    pos_ctrl_auto_tune.kpl= (pos_ctrl_auto_tune.kpl*100)/140;
                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_4)//step 4
            {
                if(pos_ctrl_auto_tune.overshoot_max<((20*pos_ctrl_auto_tune.step_amplitude)/1000) && pos_ctrl_auto_tune.err_energy_ss_int<(pos_ctrl_auto_tune.err_energy_ss_limit_soft))
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }
                else
                {
                    if(pos_ctrl_auto_tune.tuning_process_ended==0)
                        pos_ctrl_auto_tune.kpi -= 5;

                    if(pos_ctrl_auto_tune.kpi<5 && pos_ctrl_auto_tune.tuning_process_ended==0)
                    {
                        pos_ctrl_auto_tune.kpi = 5;
                        pos_ctrl_auto_tune.active_step_counter++;
                    }
                    else
                        pos_ctrl_auto_tune.active_step_counter=0;
                }

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=AUTO_TUNE_STEP_5;
                    pos_ctrl_auto_tune.active_step_counter=0;

                    pos_ctrl_auto_tune.err_energy_ss_int_min    = pos_ctrl_auto_tune.err_energy_ss_limit_soft;
                }

            }

            if(pos_ctrl_auto_tune.active_step==AUTO_TUNE_STEP_5)// step 5
            {

                if(pos_ctrl_auto_tune.err_energy_ss_int < 10*pos_ctrl_auto_tune.err_energy_ss_int_min)
                {
                    pos_ctrl_auto_tune.kpl+=50;
                }
                else
                {
                    pos_ctrl_auto_tune.active_step_counter++;
                }

                if(pos_ctrl_auto_tune.err_energy_ss_int<pos_ctrl_auto_tune.err_energy_ss_int_min)
                    pos_ctrl_auto_tune.err_energy_ss_int_min = (pos_ctrl_auto_tune.err_energy_ss_int+(3.00*pos_ctrl_auto_tune.err_energy_ss_int_min))/4.00;

                if(pos_ctrl_auto_tune.active_step_counter==10)
                {
                    pos_ctrl_auto_tune.active_step=END;

                    pos_ctrl_auto_tune.tuning_process_ended=1;
                    pos_ctrl_auto_tune.auto_tune = 0;
                    pos_ctrl_auto_tune.activate=0;

                    pos_ctrl_auto_tune.kpp *= pos_ctrl_auto_tune.kpl;
                    pos_ctrl_auto_tune.kpi *= pos_ctrl_auto_tune.kpl;
                    pos_ctrl_auto_tune.kpd *= pos_ctrl_auto_tune.kpl;
                    pos_ctrl_auto_tune.j       = 0;
                    pos_ctrl_auto_tune.kpl = 1000;

                    pos_ctrl_auto_tune.kpp /= 1000;
                    pos_ctrl_auto_tune.kpi /= 1000;
                    pos_ctrl_auto_tune.kpd /= 1000;

                    pos_ctrl_auto_tune.active_step_counter=0;
                }
            }

            if(pos_ctrl_auto_tune.rising_edge==1)
            {
                pos_ctrl_auto_tune.overshoot=0;
                pos_ctrl_auto_tune.overshoot_max=0;
            }

            pos_ctrl_auto_tune.err=0.00;
            pos_ctrl_auto_tune.err_energy =0.00;
            pos_ctrl_auto_tune.err_energy_int=0.00;

            pos_ctrl_auto_tune.err_ss=0.00;
            pos_ctrl_auto_tune.err_energy_ss =0.00;
            pos_ctrl_auto_tune.err_energy_ss_int = 0.00;

            pos_ctrl_auto_tune.counter=0;
        }
    }
    /*
     * measurement of error energy
     */
    pos_ctrl_auto_tune.err = (pos_ctrl_auto_tune.position_ref - position_k)/1000.00;
    pos_ctrl_auto_tune.err_energy = pos_ctrl_auto_tune.err * pos_ctrl_auto_tune.err;
    pos_ctrl_auto_tune.err_energy_int += pos_ctrl_auto_tune.err_energy;

    /*
     * measurement of overshoot and rise time
     */
    if(pos_ctrl_auto_tune.rising_edge==1)
    {
        pos_ctrl_auto_tune.overshoot = position_k - pos_ctrl_auto_tune.position_ref;

        if(pos_ctrl_auto_tune.overshoot > pos_ctrl_auto_tune.overshoot_max)
            pos_ctrl_auto_tune.overshoot_max=pos_ctrl_auto_tune.overshoot;
    }

    /*
     * measurement of error energy after steady state
     */
    if((90*pos_ctrl_auto_tune.counter_max)/100<pos_ctrl_auto_tune.counter && pos_ctrl_auto_tune.counter<(98*pos_ctrl_auto_tune.counter_max)/100 && pos_ctrl_auto_tune.rising_edge==1)
    {
        pos_ctrl_auto_tune.err_ss = (pos_ctrl_auto_tune.position_ref - position_k);
        pos_ctrl_auto_tune.err_energy_ss = pos_ctrl_auto_tune.err_ss * pos_ctrl_auto_tune.err_ss;
        pos_ctrl_auto_tune.err_energy_ss_int += pos_ctrl_auto_tune.err_energy_ss;
    }





    if(pos_ctrl_auto_tune.counter==0)
    {
        motion_ctrl_config.velocity_kp = pos_ctrl_auto_tune.kvp;
        motion_ctrl_config.velocity_ki = pos_ctrl_auto_tune.kvi;
        motion_ctrl_config.velocity_kd = pos_ctrl_auto_tune.kvd;
        motion_ctrl_config.velocity_integral_limit = pos_ctrl_auto_tune.kvl;
        motion_ctrl_config.moment_of_inertia       = pos_ctrl_auto_tune.j;

        motion_ctrl_config.position_kp = pos_ctrl_auto_tune.kpp;
        motion_ctrl_config.position_ki = pos_ctrl_auto_tune.kpi;
        motion_ctrl_config.position_kd = pos_ctrl_auto_tune.kpd;
        motion_ctrl_config.position_integral_limit = pos_ctrl_auto_tune.kpl;
        motion_ctrl_config.moment_of_inertia       = pos_ctrl_auto_tune.j;

        motion_ctrl_config.position_control_autotune = pos_ctrl_auto_tune.auto_tune;
    }

    return 0;
}




