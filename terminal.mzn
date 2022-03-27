%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

int: N; %number of vessels
int: L; %quay length
int: s; %max shift time
int: d; % minimum safety distance
int: C; % number of cranes
int: r; % crane range

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

%Birth window constraints OK
constraint forall(i in 1..N) (
  arrivaltimes[i] <= shifted_arrivaltimes[i] 
  /\ 
  shifted_arrivaltimes[i] <= (arrivaltimes[i] + s)
  /\
  departuretimes[i] <= shifted_departuretimes[i] 
  /\ 
  shifted_departuretimes[i] <= (departuretimes[i] + s)
);

%Duration needs to be constant OK
constraint forall(i in 1..N) (
  if (shifted_departuretimes[i] - shifted_arrivaltimes[i] > 0)
  then
    shifted_departuretimes[i] - shifted_arrivaltimes[i] 
    == 
    departuretimes[i] - arrivaltimes[i]
  else
    if (departuretimes[i] - arrivaltimes[i] < 0)
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

%Vessel position + length cannot exceed quay length OK
constraint forall(i in 1..N) (
  shipquaypositions[i] + lengths[i] <= L
);

%Vessels need to respect the safety distance
%For each ship, check if other ships in the same time window respect the safety distance
constraint forall(i in 1..N-1) (
  forall(j in i+1..N) (
    if 
      shifted_arrivaltimes[j] <= shifted_arrivaltimes[i]
      /\
      shifted_arrivaltimes[i] <= shifted_departuretimes[j]
    then
     1 != quay_overlap(i,j)
    endif
  )
);

%Helper function to check if 2 vessels have overlay on the quay
predicate quay_overlap(var int:i, var int:j) = 
  shipquaypositions[i] <= shipquaypositions[j] + lengths[j]
  /\
  shipquaypositions[i] + lengths[i] >= shipquaypositions[j];

%Helper function to calculate if 2 vessels are docked at the same time NOK
% predicate time_overlap(var int: i, var int: j)=
%   if(shifted_departuretimes[i] < shifted_arrivaltimes[i])
%   then
    
%   endif;

%Cranes cannot be assigned to multiple ships at the same time NOK
constraint forall(i in 1..N-1) (
  forall(j in i+1..N) (
    if 
      shifted_arrivaltimes[j] <= shifted_arrivaltimes[i]
      /\
      shifted_arrivaltimes[i] <= shifted_departuretimes[j]
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

solve satisfy;


