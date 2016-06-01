/**
 * @file biss_service.h
 * @author Synapticon GmbH <support@synapticon.com>
 */

#pragma once

#include <refclk.h>


#define BISS_SENSOR                4

#define ERROR                      0
#define SUCCESS                    1

#define SET_ALL_AS_QEI                 0b0011
#define SET_PORT1_AS_HALL_PORT2_AS_QEI 0b0010
#define SET_PORT1_AS_QEI_PORT2_AS_HALL 0b0001

#define BISS_POLARITY_NORMAL       0
#define BISS_POLARITY_INVERTED     1

#define BISS_MULTITURN_RESOLUTION  12
#define BISS_SINGLETURN_RESOLUTION 13
#define BISS_STATUS_LENGTH         2
#define BISS_MULTITURN_LENGTH      BISS_MULTITURN_RESOLUTION + 1 //resolution + filling bits
#define BISS_SINGLETURN_LENGTH     BISS_SINGLETURN_RESOLUTION
#define BISS_FRAME_BYTES           (( (3 + 2 + BISS_MULTITURN_LENGTH + BISS_SINGLETURN_LENGTH + BISS_STATUS_LENGTH + 6) -1)/32 + 1) //at least 3 bits + ack and start bits + data + crc
#define BISS_POLARITY              BISS_POLARITY_NORMAL
#define BISS_MAX_TICKS             0x7fffffff   // the count is reset to 0 if greater than this
#define BISS_CRC_POLY              0b110000     // poly in reverse representation:  x^0 + x^1 + x^4 is 0b1100
#define BISS_DATA_PORT_BIT         0            // bit number (0 = rightmost bit) when inputing from a multibit port
#define BISS_CLK_PORT_HIGH         (0b1000 | SET_PORT1_AS_HALL_PORT2_AS_QEI)    // high clock value when outputing the clock to a multibit port, with mode selection of ifm qei encoder and hall ports
#define BISS_CLK_PORT_LOW          SET_PORT1_AS_HALL_PORT2_AS_QEI               // low  clock value when outputing the clock to a multibit port, with mode selection of ifm qei encoder and hall ports
#define BISS_CLOCK_DIVIDEND        250          // BiSS output clock frequency: dividend/divisor in MHz
#define BISS_CLOCK_DIVISOR         20           // supported frequencies are (tile frequency) / 2n
#define BISS_USEC                  USEC_FAST    // number of ticks in a microsecond
#define BISS_VELOCITY_LOOP         100         // velocity loop time in microseconds
#define BISS_TIMEOUT               15*BISS_USEC // BiSS timeout in clock ticks
#define BISS_OFFSET_ELECTRICAL     4000


/**
 * @brief Structure type to define the BiSS Service configuration.
 */
typedef struct {
    int multiturn_length;       /**< Number of bits used for multiturn data */
    int multiturn_resolution;   /**< Number of bits of multiturn resolution */
    int singleturn_length;      /**< Number of bits used for singleturn data */
    int singleturn_resolution;  /**< Number of bits of singleturn resolution */
    int status_length;          /**< Rumber of bits used for status data */
    int crc_poly;               /**< CRC polynom in reverse representation:  x^0 + x^1 + x^4 is 0b1100 */
    int pole_pairs;             /**< Number of poles pairs to compute the electrical angle from the mechanical angle*/
    int polarity;               /**< Polarity, invert the direction */
    int clock_dividend;         /**< BiSS output clock frequency dividend */
    int clock_divisor;          /**< BiSS output clock frequency divisor */
    int timeout;                /**< Timeout after a BiSS read in clock ticks */
    int velocity_loop;          /**< Velocity loop time in microseconds */
    int max_ticks;              /**< The count is reset to 0 if greater than this */
    int offset_electrical;      /**< Offset for the electrical angle */
    int enable_push_service;
} BISSConfig;
