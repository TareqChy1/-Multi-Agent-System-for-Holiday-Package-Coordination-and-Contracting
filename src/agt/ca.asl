// Company Agent

/* Initial beliefs and rules */
max_price(300) .
min_rep(80).

/* Initial goals */

!start.

/* Plans */

/* Set-Up */

// based on template
+!start : true
    <- .print("hello world.");
       .date(Y,M,D); .time(H,Min,Sec,MilSec); // get current date & time
       +started(Y,M,D,H,Min,Sec);             // add a new belief
       .wait(8000);
       !find_toas.

/* Purchasing phase */
// plan to find a TOA for the client
+!find_toas: true
 <- ?pref_loc(L);
 !create_auction_artifact(ArtId);
 for (is_located(L)[source(A)])
 {
         !contact(A);
 };
 !wait_for_winner;
 .

+!contact(Agency)
  <- .send(Agency, tell, contact).

+is_located(Location)[source(A)]: true
    <- .print(A, " is located in ", Location).

// based on house building example
+!create_auction_artifact(ArtId) : max_price(MaxPrice) &
                                           min_rep(MinRep)
       <- .my_name(Me);
          .concat("auc_",Me, ArtName);
          makeArtifact(ArtName, "tools.PrefServ", [MaxPrice, MinRep], ArtId);
          focus(ArtId).
-!create_auction_artifact(ArtId)[error_code(Code)]
   <- .print("Error creating artifact ", Code).

+!wait_for_winner
   <- .println("Waiting...");
      .wait(5000);
      // toas cannot reject so we don't need to wait for confirmation
      !show_winner.

+!show_winner
   <- ?bestOfferAgent(Ag)[artifact_id(ArtId)];
      ?bestOfferValue(Price)[artifact_id(ArtId)];
      if (not Ag = "none")
      {
            .println("Winner of auction is ", Ag, " for ", Price);
            .send(Ag, tell, wonBid(Price));
      }
      else
      {
            .println("No TOA meets my criteria");
            .fail;

      }.


/* Delivering phase */
// Used to find the service artifact
// try to find a particular artifact and then focus on it
// taken from house building example
@alabel[atomic]
+!discover_art(ToolName)
   <- lookupArtifact(ToolName,ToolId);
      focus(ToolId).
// keep trying until the artifact is found
-!discover_art(ToolName)
   <- .wait(100);
      !discover_art(ToolName).

+!take_tour[source(SCA)]
    <- .print("Taking a tour from ", SCA);
        ?availability(A)[artifact_id(X)];
        if (not A)
        {
           .wait(1000);
           execute[artifact_id(X)];
           !take_tour[source(SCA)];
       }
       else {
       execute[artifact_id(X)];
       ?delay(D)[artifact_id(X)];
       .wait(D);
       .print("Finished the tour");
       }.

+!take_transport(M)[source(SCA)] :true
    <- .print("Taking a ", M ," from ", SCA);
       ?availability(A)[artifact_id(Art)];
       if (not A)
       {
            .wait(1000);
            execute[artifact_id(X)];
            !take_transport(M)[source(SCA)];
       }
       else
       {
       execute[artifact_id(Art)];
       ?delay(D)[artifact_id(Art)];
       .wait(D);
       .print("Arrived to destination");
       }.

+!stay_accomm[source(SCA)] :true
    <- .print("Staying at accommodation from", SCA);
       ?availability(A)[artifact_id(Art)];
       if (not A)
       {
          .wait(1000);
          execute[artifact_id(X)];
          !stay_accomm[source(SCA)];
       }
       else
       {
       execute[artifact_id(Art)];
       ?delay(D)[artifact_id(Art)];
       .wait(D);
       .print("Leaving the accommodation");
       }.

/* Organization */
// taken from building example
+!contract(GroupName)
   <- if(GroupName = "medium_group")
      {
        !in_ora4mas2;
      }
      else
      {
        !in_ora4mas;
      };
      lookupArtifact(GroupName, GroupId);
      adoptRole("client")[artifact_id(GroupId)];
      focus(GroupId).

-!contract(Service,GroupName)[error(E),error_msg(Msg),code(Cmd),code_src(Src),code_line(Line)]
   <- .print("Failed to sign the contract for ",Service,"/",GroupName,": ",Msg," (",E,"). command: ",Cmd, " on ",Src,":", Line).

+!in_ora4mas : in_ora4mas.
+!in_ora4mas : .intend(in_ora4mas)
   <- .wait({+in_ora4mas},100,_);
      !in_ora4mas.
@lin[atomic]
+!in_ora4mas
   <- joinWorkspace("ora4mas",_);
      +in_ora4mas.

// second workspace for second toa
+!in_ora4mas2 : in_ora4mas2.
+!in_ora4mas2 : .intend(in_ora4mas2)
   <- .wait({+in_ora4mas2},100,_);
      !in_ora4mas2.
@lin2[atomic]
+!in_ora4mas2
   <- joinWorkspace("ora4mas2",_);
      +in_ora4mas2.

{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

// uncomment the include below to have an agent compliant with its organisation
{ include("$moise/asl/org-obedient.asl") }
