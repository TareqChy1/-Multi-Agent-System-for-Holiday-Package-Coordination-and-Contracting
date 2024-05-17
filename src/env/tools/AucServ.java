// CArtAgO artifact code for project mac_project
// Based on the auction artifact from the house building example

package tools;

import cartago.*;

public class AucServ extends Artifact {
	void init(String service, int initialValue, int minRep) {
		defineObsProperty("service", service);
		defineObsProperty("currVal", initialValue);
		defineObsProperty("minRep", minRep);
		defineObsProperty("currWinner", "none");
        defineObsProperty("pastWinner", "none");
	}

	@OPERATION public void bid(double bidValue, int rep) {
            ObsProperty opCurrentValue  = getObsProperty("currVal");
            ObsProperty opCurrentWinner = getObsProperty("currWinner");
            ObsProperty opMinRep = getObsProperty("minRep");
            ObsProperty opPastWinners = getObsProperty("pastWinner");
            double priceDif = bidValue - opCurrentValue.doubleValue();
            boolean betterPrice = priceDif < 0;
            boolean goodRep = rep >= opMinRep.intValue() ;
            if (betterPrice && goodRep) {  // the price is lower and the rep didnt drop too much
                opCurrentValue.updateValue(bidValue);
                opPastWinners.updateValue(opCurrentWinner.stringValue());
                opCurrentWinner.updateValue(getCurrentOpAgentId().getAgentName());


            }
        }

}

