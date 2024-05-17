package tools;

import cartago.*;

import java.util.HashMap;
import java.util.Map;

public class PrefServ extends Artifact {

    // Initialization Method with Customer Preferences
    void init(int initialMaxPrice, int minRep) {
        defineObsProperty("bestOfferValue", initialMaxPrice);
        defineObsProperty("minRep", minRep);
        defineObsProperty("bestOfferAgent", "none");

        log("PrefServ initialized, initialMaxPrice: " + initialMaxPrice
                + ", minRep: " + minRep);
    }

    // Enhanced Bid Operation
    @OPERATION public void bid(double bidValue, int rep) {
        ObsProperty opBestOfferValue = getObsProperty("bestOfferValue");
        ObsProperty opBestOfferAgent = getObsProperty("bestOfferAgent");
        ObsProperty opMinRep = getObsProperty("minRep");
        AgentId bidder = getCurrentOpAgentId();

        // Check if the bid meets price and reputation criteria
        boolean meetsPriceCriteria = bidValue <= opBestOfferValue.doubleValue();
        boolean meetsRepCriteria = rep >= opMinRep.intValue();

        // Evaluate the bid based on the combined criteria
        if (meetsPriceCriteria && meetsRepCriteria) {
            opBestOfferValue.updateValue(bidValue);
            opBestOfferAgent.updateValue(bidder.getAgentName());
            log("New best offer from " + bidder.getAgentName() + " with value: " + bidValue);
        } else {
            log("Bid from " + bidder.getAgentName() + " rejected. Bid value: " + bidValue
                    + ", Reputation: " + rep);
        }
    }

    // Helper method for logging
    public void log(String message) {
        this.signal("log", message);
    }
}
