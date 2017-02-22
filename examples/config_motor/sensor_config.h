// default sensor config

#pragma once

//General config
#define SENSOR_MAX_TICKS                  0x7fffffff   // the count is reset to 0 if greater than this
#define SENSOR_VELOCITY_COMPUTE_PERIOD    1000         // default velocity compute period 1ms

//BiSS config, use default if not set before
#ifndef BISS_CONFIG
#define BISS_MULTITURN_RESOLUTION  10
#define BISS_SINGLETURN_RESOLUTION 18
#define BISS_FILLING_BITS          0
#define BISS_CRC_POLY              0b110000     // poly in reverse representation:  x^0 + x^1 + x^4 is 0b1100
#define BISS_CLOCK_FREQUENCY       4000         // BiSS output clock frequency in kHz
#define BISS_VELOCITY_COMPUTE_PERIOD 50         // velocity loop time in microseconds
#define BISS_TIMEOUT               20*IFM_TILE_USEC // BiSS timeout in clock ticks
#define BISS_BUSY                  30
#define BISS_CLOCK_PORT            BISS_CLOCK_PORT_EXT_D5
#define BISS_DATA_PORT             BISS_DATA_PORT_2
#endif

//REM 16MT config
#define REM_16MT_FILTER            0x02
#define REM_16MT_VELOCITY_COMPUTE_PERIOD     53

//REM 14 config
#define REM_14_CACHE_TIME          (60*IFM_TILE_USEC)
#define REM_14_VELOCITY_COMPUTE_PERIOD       30

//QEI config
#define QEI_SENSOR_INDEX_TYPE        QEI_WITH_INDEX     // [QEI_WITH_INDEX, QEI_WITH_NO_INDEX]
#define QEI_SENSOR_SIGNAL_TYPE       QEI_RS422_SIGNAL   // [QEI_RS422_SIGNAL, QEI_TTL_SIGNAL]
#define QEI_SENSOR_RESOLUTION        4000               // ticks per turn = 4 * CPR (Cycles per revolution)


// Sensor resolution (count per revolution)
// and velocity compute period

//Manual setting
//#define COMMUTATION_SENSOR_RESOLUTION   65536
//#define FEEDBACK_SENSOR_RESOLUTION      65536
//#define COMMUTATION_VELOCITY_COMPUTE_PERIOD   1000
//#define FEEDBACK_VELOCITY_COMPUTE_PERIOD      1000

//auto set commutation and feedback sensor resolution/velocity compute period depending on sensor used
#if ! defined(COMMUTATION_SENSOR_RESOLUTION) || ! defined(COMMUTATION_VELOCITY_COMPUTE_PERIOD)
#if (MOTOR_COMMUTATION_SENSOR == BISS_SENSOR)
#define COMMUTATION_SENSOR_RESOLUTION (1<<BISS_SINGLETURN_RESOLUTION)
#define COMMUTATION_VELOCITY_COMPUTE_PERIOD  BISS_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_COMMUTATION_SENSOR == REM_16MT_SENSOR)
#define COMMUTATION_SENSOR_RESOLUTION (1<<16)
#define COMMUTATION_VELOCITY_COMPUTE_PERIOD REM_16MT_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_COMMUTATION_SENSOR == REM_14_SENSOR)
#define COMMUTATION_SENSOR_RESOLUTION (1<<14)
#define COMMUTATION_VELOCITY_COMPUTE_PERIOD REM_14_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_COMMUTATION_SENSOR == HALL_SENSOR)
#define COMMUTATION_SENSOR_RESOLUTION 4096*POLE_PAIRS
#define COMMUTATION_VELOCITY_COMPUTE_PERIOD SENSOR_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_COMMUTATION_SENSOR == QEI_SENSOR)
#define COMMUTATION_SENSOR_RESOLUTION QEI_SENSOR_RESOLUTION
#define COMMUTATION_VELOCITY_COMPUTE_PERIOD SENSOR_VELOCITY_COMPUTE_PERIOD
#endif
#endif


#if ! defined(FEEDBACK_SENSOR_RESOLUTION) || ! defined(FEEDBACK_VELOCITY_COMPUTE_PERIOD)
#if (MOTOR_FEEDBACK_SENSOR == BISS_SENSOR)
#define FEEDBACK_SENSOR_RESOLUTION (1<<BISS_SINGLETURN_RESOLUTION)
#define FEEDBACK_VELOCITY_COMPUTE_PERIOD  BISS_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_FEEDBACK_SENSOR == REM_16MT_SENSOR)
#define FEEDBACK_SENSOR_RESOLUTION (1<<16)
#define FEEDBACK_VELOCITY_COMPUTE_PERIOD REM_16MT_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_FEEDBACK_SENSOR == REM_14_SENSOR)
#define FEEDBACK_SENSOR_RESOLUTION (1<<14)
#define FEEDBACK_VELOCITY_COMPUTE_PERIOD REM_14_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_FEEDBACK_SENSOR == HALL_SENSOR)
#define FEEDBACK_SENSOR_RESOLUTION 4096*POLE_PAIRS
#define FEEDBACK_VELOCITY_COMPUTE_PERIOD SENSOR_VELOCITY_COMPUTE_PERIOD
#elif (MOTOR_FEEDBACK_SENSOR == QEI_SENSOR)
#define FEEDBACK_SENSOR_RESOLUTION QEI_SENSOR_RESOLUTION
#define FEEDBACK_VELOCITY_COMPUTE_PERIOD SENSOR_VELOCITY_COMPUTE_PERIOD
#endif
#endif
