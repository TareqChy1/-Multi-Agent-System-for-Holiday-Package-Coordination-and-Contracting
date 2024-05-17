// Service Company Agent

/* Initial beliefs and rules */

// Used for adopting roles in org
task_roles("Transport",         [transporter]).
task_roles("Tours",         [tour_operator]).
task_roles("Accommodation",         [host]).

/* Initial goals */

!start.


/* Plans */

/* Set-up */

// based on template
+!start : .my_name(Me)
    <- .print("hello world it's ", Me);
       !randomize;
       !share_location;
       !share_services;
       .date(Y,M,D); .time(H,Min,Sec,MilSec); // get current date & time
       +started(Y,M,D,H,Min,Sec).             // add a new belief

// Randomly generate services, prices, reputation and location
+!randomize
    <- .random([50,100,200],Z);
     +my_reputation(Z);
     .random(["Paris", "Nice","Nantes", "Bordeaux", "Brest", "Marseille"],L);
     +location(L);
    for (.range(I, 1, 3))
    {
       .random(X);
       if (X > 0.5)
       {
         .random(Y);
         if (I = 1)
         {
            +my_service("Tours");
            +my_price("Tours", 50 + Y*10);
         }
         elif (I = 2)
         {
            +my_service("Transport");
            +my_price("Transport", 70 +Y*20);
         }
         else
         {
            +my_service("Accommodation");
            +my_price("Accommodation", 80 + Y*20);
         };
       };
    }.



//tell the toa what my services are
+!share_services : true
    <- for(my_service(Service))
    {
    .send(toa, tell, has_service(Service));
    .send(toa1, tell, has_service(Service));
    };
    .
// tell the toa where im located
+!share_location : location(Location)
    <- .send(toa, tell, is_located(Location));
    .send(toa1, tell, is_located(Location)).

/* Contracting phase */
+contact(Service)[source(A)] : true
   <- .print("The TOA ", A, " is interested in my service ", Service);
      .concat("auc_",Service,A,ArtName);
      !discover_art(ArtName).

// Used to find an interested TOAs auction artifact
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

+service(S)[artifact_id(Art)]:
my_price(S, P) &
my_reputation(R)
   <- bid(P, R)[artifact_id(Art)];
      .print("Just placed a bid for ", S).

+wonBid(S, P)[source(T)]: true
    <- .print("I won the bid for ", S, " for the agency ", T);
       .findall(W, wonBid(S, W)[source(_)], K);
       .max(K, M);
       ?wonBid(S, M)[source(Q)];
       .print("TOA with max profit is ", Q);
       if (Q = T)
       {
        .min(K, N);
        ?wonBid(S, N)[source(V)];
        .send(T, tell, confirmWin(S));
        if (not N = M)
        {
            .send(V, tell, rejectWin(S));
            -wonBid(S,N)[source(V)];
        }
       }
       else
       {
        .send(T, tell, rejectWin(S));
        -wonBid(S, P)[source(T)];
       }.

/* Delivering phase */
+!provideTourService: my_service("Tours")
<-  ?location(L);
    .concat("serv_",L,"_tours",ArtName);
    lookupArtifact(ArtName,ArtId);
    focus(ArtId);
    ?client("Tours", C);
    .send(C, achieve, discover_art(ArtName));
    .my_name(Me);
    .send(C, achieve, take_tour).

-!provideTourService: my_service("Tours")
<- ?location(L);
   .concat("serv_",L,"_tours",ArtName);
   makeArtifact(ArtName, "tools.ServPlace", ["Tours", L, 5000], ArtId);
   !provideTourService.

+!provideTransportService: my_service("Transport")
<-  ?location(L);
    .concat("serv_",L,"_transport",ArtName);
    lookupArtifact(ArtName,ArtId);
    focus(ArtId);
    ?client("Transport", C);
    .send(C, achieve, discover_art(ArtName));
    .my_name(Me);
    .send(C, achieve, take_transport("train")).

-!provideTransportService: my_service("Transport")
<- ?location(L);
   .concat("serv_",L,"_transport",ArtName);
   makeArtifact(ArtName, "tools.ServPlace", ["Transport", L, 2000], ArtId);
   !provideTransportService.

// redirect for orgs
+!provideTransportServiceArrival
<- !provideTransportService.


+!provideTransportServiceDeparture
<- !provideTransportService.

+!provideAccommService: my_service("Accommodation")
<-  ?location(L);
    .concat("serv_",L,"_accomm",ArtName);
    lookupArtifact(ArtName,ArtId);
    focus(ArtId);
    ?client("Accommodation", C);
    .send(C, achieve, discover_art(ArtName));
    .my_name(Me);
    .send(C, achieve, stay_accomm).

-!provideAccommService: my_service("Accommodation")
<- ?location(L);
   .concat("serv_",L,"_accomm",ArtName);
   makeArtifact(ArtName, "tools.ServPlace", ["Accommodation", L, 8000], ArtId);
   !provideAccommService.

/* Organization */
// taken from building example
+!contract(Task,GroupName)
    : task_roles(Task,Roles)
   <- if(GroupName = "medium_group")
      {
        !in_ora4mas2;
      }
      else
      {
        !in_ora4mas;
      };
      lookupArtifact(GroupName, GroupId);
      for ( .member( Role, Roles) ) {
         adoptRole(Role)[artifact_id(GroupId)];
         focus(GroupId)
      }.

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
