// CArtAgO artifact code for project mac_project
// Based on the AucServ artifact

package tools;

import cartago.*;

public class ServPlace extends Artifact {

    void init(String service, String place, Integer delay) {
        defineObsProperty("serviceOff", service);
        defineObsProperty("place", place);
        defineObsProperty("availability", true);
        defineObsProperty("lastexecuted", 0);
        defineObsProperty("delay", delay);
    }

    @OPERATION public void execute() {
        ObsProperty opAvailability  = getObsProperty("availability");
        ObsProperty opLastExecuted  = getObsProperty("lastexecuted");
        ObsProperty delay  = getObsProperty("delay");
        boolean available = opAvailability.booleanValue();
        Long now = System.currentTimeMillis();
        if (available)
        {
            opLastExecuted.updateValue(now);
            opAvailability.updateValue(false);
        }
        else
        {
            Integer lastExecuted = opLastExecuted.intValue();
            if (now - lastExecuted >= delay.intValue())
            {
                opAvailability.updateValue(true);
            }
        }
    }

}

