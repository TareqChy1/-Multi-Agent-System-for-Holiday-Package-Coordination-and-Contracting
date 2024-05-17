// Tour Operator Agent

/* Initial beliefs and rules */
need_service("Transport").
need_service("Accommodation").
need_service("Tours").

max_price("Transport", 90).
max_price("Accommodation", 180).
max_price("Tours", 150).

min_rep("Transport", 60).
min_rep("Accommodation", 90).
min_rep("Tours", 75).

my_price(200).
my_reputation(200).

client(bob).
client(bobbette).

/* Initial goals */

!start.

/* Plans */

/* Set-Up */

+!start : true
    <- .print("hello world.");
       .date(Y,M,D); .time(H,Min,Sec,MilSec); // get current date & time
       +started(Y,M,D,H,Min,Sec); // add a new belief
       .random(["Paris", "Nice","Nantes"],L);
       +location(L);
       !share_location;
       .wait(500).
       !find_agencies .

/* Contracting phase */
+has_service(Service)[source(A)]: true
    <- .print(A, " provides the service ", Service).

+is_located(Location)[source(A)]: true
    <- .print(A, " is located in ", Location).

// plan to find an agency for each service
+!find_agencies: true
 <- for(need_service(Service))
 {
    !create_auction_artifact(Service, ArtId);
    for (has_service(Service)[source(A)])
    {
        !contact(Service, A);
    };
 };
 !wait_for_winners;
 .

+!contact(Service, Agency)
 : location(Location) &
  is_located(Location)[source(Agency)]
  <- .send(Agency, tell, contact(Service)).

-!contact(Service, Agency)
 <- .print(Agency, " does not have the correct location").

+!create_auction_artifact(Service,ArtId) : max_price(Service, MaxPrice) &
                                           min_rep(Service, MinRep)
       <- .my_name(Me);
          .concat("auc_",Service,Me, ArtName);
          makeArtifact(ArtName, "tools.AucServ", [Service, MaxPrice, MinRep], ArtId);
          focus(ArtId).
-!create_auction_artifact(Service, ArtId)[error_code(Code)]
   <- .print("Error creating artifact ", Code).

+!wait_for_winners
   <- .println("Waiting...");
      .wait(5000);
      !show_winners;
      // wait for their confirmation or rejection
      .wait(5000).

+!show_winners
   <- for ( currWinner(Ag)[artifact_id(ArtId)] ) {
         ?currVal(Price)[artifact_id(ArtId)]; // check the current bid
         ?service(Service)[artifact_id(ArtId)];          // and the task it is for
         .println("Winner of service ", Service," is ", Ag, " for ", Price);
         .send(Ag, tell, wonBid(Service, Price));
      };
      .

+confirmWin(S) : true
    <- .println("Winner has confirmed their commitment").

+rejectWin(S): true
    <- .println("Winner has rejected the service, trying the runner up.");
       ?service(S)[artifact_id(ArtId)];
       ?pastWinner(W)[artifact_id(ArtId)];
       if (not W = "none")
       {
        ?currVal(Price)[artifact_id(ArtId)];
        .send(W, tell, wonBid(S, Price));
       }.


-rejectWin(S)
    <- .println("Could not find service company").


/* Purchasing phase */

// send the client your location
+!share_location
    <- ?location(Location);
    for (client(C))
    {
        .send(C, tell, is_located(Location));
    }.

+contact[source(A)] : true
    <- .print("The client ", A, " is interested in my package");
       .concat("auc_",A,ArtName);
       !discover_art(ArtName);
       ?my_price(P);
       ?my_reputation(R);
       ?bestOfferAgent(Ag)[artifact_id(Art)];
       bid(P, R)[artifact_id(Art)];
       .print("Just placed a bid for ", A).

// try to find a particular artifact and then focus on it
@alabel[atomic]
+!discover_art(ToolName)
   <- lookupArtifact(ToolName,ToolId);
      focus(ToolId).
// keep trying until the artifact is found
-!discover_art(ToolName)
   <- .wait(100);
      !discover_art(ToolName).

// client tells me i won
+wonBid(Price)[source(C)]
    <- .println("I won the auction for the client ", C);
       +myclient(C);
       for ( confirmWin(S)[source(A)]) {
         !sendClient(C, S, A);
       }.

+!sendClient(C, S, A): true
    <- .print(A, " will provide the service ", S, " for my client ", C);
        .send(A, tell, client(S, C)).


/* Organization and Delivery Phase */
+!go <-
      // create the organisation for managing the packages
      .my_name(Me);
      createWorkspace("ora4mas2");
      joinWorkspace("ora4mas2",WOrg);

      // NB.: we (have to) use the same id for OrgBoard and Workspace (ora4mas in this example)
      makeArtifact(ora4mas2, "ora4mas.nopl.OrgBoard", ["src/org/medium_org.xml"], OrgArtId)[wid(WOrg)];
      focus(OrgArtId);
      // create the group and adopt the role supervisor
      createGroup(medium_group, toa_group, GrArtId);
      debug(inspector_gui(on))[artifact_id(GrArtId)];
      adoptRole(supervisor)[artifact_id(GrArtId)];
      focus(GrArtId);

      // sub-goal for contracting the winner and making them enter enter into the group
      !contract_winners("medium_group");

      // create the scheme
      createScheme(bhsch, medium_package, SchArtId);
      debug(inspector_gui(on))[artifact_id(SchArtId)];
      focus(SchArtId);

      ?formationStatus(ok)[artifact_id(GrArtId)]; // see plan below to ensure we wait until it is well formed
      addScheme("bhsch")[artifact_id(GrArtId)];
      commitMission("complete_medium_package")[artifact_id(SchArtId)];
      .
// taken from house building ex
// plan for contracting with each of the winning company in case we have all winners
+!contract_winners(GroupName) : true
   <- for ( confirmWin(S)[source(A)]) {
            println("Contracting ",A," for ", S);
            // sends the message to the agent notifying it about the result
            .send(A, achieve, contract(S,GroupName))
      };
      ?myclient(C);
      .send(C, achieve, contract(GroupName)).

// plan for contracting in case we don't have enough winners
+!contract_winners(_)
   <- println("** I didn't find enough service companies!");
      .fail.

// Plans to wait until the group is well formed
// Makes this intention suspend until the group is believed to be well formed
+?formationStatus(ok)[artifact_id(G)]
   <- .wait({+formationStatus(ok)[artifact_id(G)]}).

+!medium_goal
    <- .println("Supervising...").


{ include("$jacamo/templates/common-cartago.asl") }
{ include("$jacamo/templates/common-moise.asl") }

// uncomment the include below to have an agent compliant with its organisation
{ include("$moise/asl/org-obedient.asl") }
