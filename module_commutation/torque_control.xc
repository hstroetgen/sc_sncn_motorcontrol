#include "varext.h"
#include "def.h"


void    function_TorqueControl()
{
	switch(iStep1)
	{
		case 0: iPwmOnOff 		 = 0;
				iIntegralGain    = 0;
				iUmotProfile     = 0;
				iUmotResult      = 0;
				iSetSpeedRamp    = 0;
				iMotDirection    = 0;
				if(iTorqueSet > 0){iMotDirection =   1; VsqRef1 = 4096;  iStep1 = 10;}
				if(iTorqueSet < 0){iMotDirection =  -1; VsqRef1 =-4096;  iStep1 = 10;}
				break;

				//==========================================
		case 10: iPwmOnOff 		 = 1;
				 if(iTorqueSet == 0)iStep1 = 0;
				 if(iControlFOC ==0)iStep1 = 0;
				 break;

		//--------------- overcurrent --------------------------
		case 30:  iPwmOnOff		  = 0;			// error motor stop
				  iStep1++;
				  break;

		case 31:  iPwmOnOff		  =  0;
		 	 	  if(iControlFOC > 1){
		 	 	  if(iTorqueSet == 0 ) iStep1=0;
		 	 	  }
		 	 	  else
		 	 	  {
				  if(iSetLoopSpeed== 0)iStep1=0;     // motor is stopping
		 	 	  }
		 	 	  break;
		default:
				#ifdef DEBUG_commutation
					printstr("error\n");
				#endif
				iStep1 = 0;
				break;
	}// end iStep1


	//===========================================================
	//	CalcRampForSpeed();
	//============================== ramp calculation ===========

		FOC_ClarkeAndPark();


		iFieldDiff1     = iFieldSet  - iId;
		iTorqueDiff1    = iTorqueSet - iIq;  // <<<=== iTorqueSet

		FOC_FilterDiffValue();

		VsdRef1 += iFieldDiff2  /16;
		VsqRef1 += iTorqueDiff2 /4;								// FOC torque-control


		FOC_InversPark();


		iUmotResult = iVectorInvPark/2;		// FOC torque-control


}