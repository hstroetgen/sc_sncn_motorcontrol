#define VELOCITY_CTRL_ENABLE()   	c_velocity_ctrl <: 1
#define VELOCITY_CTRL_DISABLE()  	c_velocity_ctrl <: 0
#define VELOCITY_CTRL_READ(x)		c_velocity_ctrl :> x
#define VELOCITY_CTRL_WRITE(x)		c_velocity_ctrl <: x

#define SUCCESS 1
#define ERROR   0 //based on timeout for success
#define CSV 9