/**
 * @file position_feedback_common.h
 * @author Synapticon GmbH <support@synapticon.com>
 */


#pragma once


/**
 * @brief Type for Encoder Port
 *
 * There are two identical encoder ports which can be used for Hall, QEI and BiSS.
 */
typedef enum {
    ENCODER_PORT_1 = 0,  /**< Encoder port 1 (value should be 0) */
    ENCODER_PORT_2 = 1   /**< Encoder port 0 (value should be 1) */
} EncoderPortNumber;


/**
 * @brief Type for the kind of Encoder output signals.
 */
typedef enum {
    ENCODER_PORT_RS422_SIGNAL=0,    /**< Encoder signal input over RS422 (differential). */
    ENCODER_PORT_TTL_SIGNAL         /**< Encoder signal input over standard TTL signal.  */
} EncoderPortSignalType;
