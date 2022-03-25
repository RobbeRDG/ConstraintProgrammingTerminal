%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Shifted time windows
array[1..N] of var 0..s: shifted_arrivaltimes;
array[1..N] of var 0..s: shifted_departuretimes;

%Quay positions of ship
array[1..N] of var 0..L: shipquaypositions;

%Crane assignments
array[1..N,1..C] of var 0..1: assignedcranes;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Constraints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Birth window constraints
constraint forall(i in N) (
  arrivaltimes[i] <= shifted_arrivaltimes[i] 
  /\ 
  shifted_arrivaltimes[i] <= (arrivaltimes[i] + s)
  /\
  departuretimes[i] <= shifted_departuretimes[i] 
  /\ 
  shifted_departuretimes[i] <= (departuretimes[i] + s)
);

%Duration needs to be constant
constraint forall(i in N) (
  shifted_departuretimes[i] - shifted_arrivaltimes[i] 
  == 
  departuretimes[i] - arrivaltimes[i]
);

%Vessel position + length cannot exceed quay length
constraint forall(i in N) (
  shipquaypositions[i] + lengths[i] <= L
);

%Vessels need to respect the safety distance
%For each ship, check if other ships in the same time window respect the safety distance
constraint forall(i in N) (
  forall(j in N) (
    if 
      shifted_arrivaltime[j] <= shifted_arrivaltime[i]
      /\
      shifted_arrivaltime[i] <= shifted_departuretime[j]
    then
     1 != overlap(i,j)
    endif
  );
);

predicate overlap(var int:i, var int:j) = 
  shipquaypositions[i] <= shipquaypositions[j] + lengths[j]
  /\
  shipquaypositions[i] + lengths[i] >= shipquaypositions[j]


%Cranes cannot be assigned to multiple ships at the same time
constraint forall(i in N) (
  forall(j in N) (
    if 
      shifted_arrivaltime[j] <= shifted_arrivaltime[i]
      /\
      shifted_arrivaltime[i] <= shifted_departuretime[j]
    then
      forall(k in C) (
        !=(
          assignedcranes[i][k] == 1
          /\
          assignedcranes[j][k] == 1
         );
      );
  );
);
  

%Quay crane needs to be able to reach the assigned vessel



solve satisfy;


