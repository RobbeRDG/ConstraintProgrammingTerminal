%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

int: N; % number of vessels
int: L; % quay length
int: s; % max shift time
int: d; % minimum safety distance
int: C; % number of cranes
int: r; % crane range

array[1..2] of string: test_array = ["",","];

%Quay basepositions of cranes
array[1..C] of var 0..L: qcbasepositions;

%Length of ships
array[1..N] of var 1..L: lengths;

%Arrival and departure times of ships
array[1..N] of var 0..168: arrivaltimes;
array[1..N] of var 0..168: departuretimes;

%Minimum number of cranes needed per ship
array[1..N] of var 0..C: minimumnumqcs;

%Quay positions of ship
array[1..N] of var 0..L: shipquaypositions;

%Crane assignments
array[1..N,1..C] of var 0..1: assignedcranes;

%Shifted time windows
array[1..N] of var 0..168: shifted_arrivaltimes;
array[1..N] of var 0..168: shifted_departuretimes;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Birth window constraints
constraint forall(i in 1..N) (
  arrivaltimes[i] <= shifted_arrivaltimes[i] 
  /\ 
  shifted_arrivaltimes[i] <= (arrivaltimes[i] + s)
  /\
  departuretimes[i] <= shifted_departuretimes[i] 
  /\ 
  shifted_departuretimes[i] <= (departuretimes[i] + s)
);

%Duration needs to be constant 
constraint forall(i in 1..N) (
  if (shifted_departuretimes[i] > shifted_arrivaltimes[i])
  then
    shifted_departuretimes[i] - shifted_arrivaltimes[i] 
    == 
    departuretimes[i] - arrivaltimes[i]
  else
    if (departuretimes[i] < arrivaltimes[i])
    then
      shifted_departuretimes[i] - shifted_arrivaltimes[i] 
      == 
      departuretimes[i] - arrivaltimes[i]
    else
      shifted_departuretimes[i] - shifted_arrivaltimes[i] 
      +
      departuretimes[i] - arrivaltimes[i]
      ==
      168
    endif
  endif
);

%Vessel position + length cannot exceed quay length 
constraint forall(i in 1..N) (
  shipquaypositions[i] + lengths[i] <= L
);

%Vessels need to respect the safety distance
%For each ship, check if other ships in the same time window respect the safety distance
constraint forall(i in 1..N-1) (
  forall(j in i+1..N) (
    if 
     time_overlay(i,j) == 1
    then
     quay_overlay(i,j) != 1 /\ check_safety_dist(i,j) == 1
    endif
  )
);

%Helper function to check if 2 vessels have overlay on the quay
predicate quay_overlay(var int:i, var int:j) = 
  shipquaypositions[i] < shipquaypositions[j] + lengths[j]
  /\
  shipquaypositions[i] + lengths[i] > shipquaypositions[j];
    
%Helper function to check if 2 vessels respect the safety distance
predicate check_safety_dist(var int:i, var int:j) =
  (shipquaypositions[i] + lengths[i] + d <= shipquaypositions[j]
    \/ shipquaypositions[j] + lengths[j] + d <= shipquaypositions[i]);

%Helper function to calculate if 2 vessels are docked at the same time 
predicate time_overlay(var int: i, var int: j)=( 
  if(shifted_departuretimes[i] > shifted_arrivaltimes[i] /\ shifted_departuretimes[j] > shifted_arrivaltimes[j])
  then
    shifted_arrivaltimes[i] < shifted_departuretimes[j] /\ shifted_departuretimes[i] > shifted_arrivaltimes[j]
  elseif
    shifted_departuretimes[i] > shifted_arrivaltimes[i] /\ shifted_departuretimes[j] < shifted_arrivaltimes[j]
  then
    shifted_arrivaltimes[i] < shifted_departuretimes[j] \/ shifted_departuretimes[i] > shifted_arrivaltimes[j]
  elseif
    shifted_departuretimes[i] < shifted_arrivaltimes[i] /\ shifted_departuretimes[j] > shifted_arrivaltimes[j]
  then
    shifted_arrivaltimes[i] > shifted_arrivaltimes[j] \/ shifted_departuretimes[i] < shifted_departuretimes[j]
  else
    true
  endif
  );

%Cranes cannot be assigned to multiple ships at the same time 
constraint forall(i in 1..N-1) (
  forall(j in i+1..N) (
    if 
      time_overlay(i,j) == 1
    then
      forall(k in 1..C) (
          assignedcranes[i,k] != 1
          \/
          assignedcranes[j,k] != 1
      )
    endif
  )
);

%All vessels have their minimum of cranes assigned
constraint forall(i in 1..N)(
  sum(j in 1..C)(assignedcranes[i,j]) >= minimumnumqcs[i]
  );
 
%Quay crane needs to be able to reach the assigned vessel
constraint forall(i in 1..N)(
  forall(j in 1..C)(
    if(assignedcranes[i,j] == 1)
    then
      shipquaypositions[i] + lengths[i] <= qcbasepositions[j] + r
      /\
      shipquaypositions[i] >= qcbasepositions[j]
    endif
  )
);

 
solve satisfy;

output [
        concat([show(n) ++ ":" 
        ++ show(shipquaypositions[n]) ++ "-" ++ show(shipquaypositions[n]+lengths[n]) ++ ";"
        ++ show(shifted_arrivaltimes[n]) ++ ".." ++ show(shifted_departuretimes[n]) ++ ";"
        ++ concat([show(assignedcranes[n,c]*c) ++ "," | c in 1..C where show(assignedcranes[n,c]) == show(1)]) ++ "\n"
        | n in 1..N])
       ];
        
