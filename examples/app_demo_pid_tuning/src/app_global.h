/**
 * The copyrights, all other intellectual and industrial
 * property rights are retained by XMOS and/or its licensors.
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the
 * copyright notice above.
 **/
#ifndef _APP_GLOBAL_H_
#define _APP_GLOBAL_H_


/** Define the number of motors */
#define NUMBER_OF_MOTORS 1

/*recuperation mode
 * WARNING: explosion danger. This mode shoule not be activated before evaluating battery behaviour.*/
#define RECUPERATION     0

/** Define Motor Identifier (0 or 1) */
#define MOTOR_ID 0


/** Define the resolution of PWM (WARNING: effects update rate as tied to ref clock) */
//MB~ #define PWM_RES_BITS 12 // Number of bits used to define number of different PWM pulse-widths
#define PWM_RES_BITS 14 // Number of bits used to define number of different PWM pulse-widths
#define PWM_MAX_VALUE (1 << PWM_RES_BITS) // No.of different PWM pulse-widths = 16384

#define PWM_MIN_LIMIT (PWM_MAX_VALUE >> 4) // Min PWM value allowed (1/16th of max range) = 1024
#define PWM_MAX_LIMIT (PWM_MAX_VALUE - PWM_MIN_LIMIT) // Max. PWM value allowed = (16384-1024) = 15360


#define PWM_DEAD_TIME 1500 //((12 * MICRO_SEC + 5) / 10) // 1200ns PWM Dead-Time WARNING: Safety critical

// Number of PWM time increments between ADC/PWM synchronisation points. NB Independent of Reference Frequency
#define INIT_SYNC_INCREMENT (PWM_MAX_VALUE)
#define HALF_SYNC_INCREMENT (INIT_SYNC_INCREMENT >> 1)

#define ADC_TRIG_INCREMENT  (50*(INIT_SYNC_INCREMENT/100))

#define PWM_TRIG_INCREMENT  (80*(INIT_SYNC_INCREMENT/100))


// The time each motor starts the PWM is staggered by this amount
#define PWM_STAGGER ((INIT_SYNC_INCREMENT + (NUMBER_OF_MOTORS >> 1)) / NUMBER_OF_MOTORS)

// If locked, the ADC sampling will occur in the middle of the  switching sequence.
// It is triggered over a channel. Set this define to 0 to disable this feature
/** Define sync. mode for ADC sampling. Default 1 is 'ADC synchronised to PWM' */
#define LOCK_ADC_TO_PWM 1

/** Define if Shared Memory is used to transfer PWM data from Client to Server */
#define PWM_SHARED_MEM 0 // 0: Use c_pwm channel for pwm data transfer

/** Maximum Port timer value. See also PORT_TIME_TYP */
#define PORT_TIME_MASK 0xFFFF

/* This is a bit of a cludge, we are using a non-standard configuration
 * where the timer on the tile for inner_loop() is running at 250 MHz,
 * but other timers are running at the default of 100 MHz.
 * Currently this flexibility to define timer frequencies for each tile does not exist.
 * Therefore, we set up the timer frequency here.
 */
#ifndef PLATFORM_REFERENCE_MHZ
#define PLATFORM_REFERENCE_MHZ 250//100
#define PLATFORM_REFERENCE_KHZ (1000 * PLATFORM_REFERENCE_MHZ)
#define PLATFORM_REFERENCE_HZ  (1000 * PLATFORM_REFERENCE_KHZ) // NB Uses 28-bits
#endif

#define SECOND PLATFORM_REFERENCE_HZ // One Second in Clock ticks
#define MILLI_SEC (PLATFORM_REFERENCE_KHZ) // One milli-second in clock ticks
#define MICRO_SEC (PLATFORM_REFERENCE_MHZ) // One micro-second in clock ticks

#define QUART_PWM_MAX (PWM_MAX_VALUE >> 2)  // Quarter of maximum PWM width value


/** Type for Port timer values. See also PORT_TIME_MASK */
typedef unsigned short PORT_TIME_TYP;

#endif /* _APP_GLOBAL_H_ */
