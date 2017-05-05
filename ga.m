function [aopt, fopt] = ga(evalbudget)
  % Genetic algorithm to determine the best configuration that minimizes the
  % power loss in a power distribution network.
  %
  % Input is the number of evaluations the algorithm makes
  %
  % The function returns:
  %     - aopt: the best found network configuration
  %     - fopt: the minimal power loss corresponding to the best network configuration aopt
  
  % The population is encoded into three variables:
  %   P = {pop_pheno, pop_geno, power_loss}
  % where pop_pheno is an integer configuration, pop_geno the corresponding
  % bit string representation and power_loss the corresponding lost power
  % in kW

  % GA parameters
  mu = 20;  % population size
  pc = 0.9;    % crossover probability
  pm = 0.01;    % mutation probability
  k_tourney = ceil(mu/3); %  Tournament size
  pt = 0.9;  % tournament selection probability
  npoint = 6; % amount of crossover points

  % Set upperbounds, taken over from valid_119.m 
  ub = [25;17;15;21;18;12;11;16;12;17;20;18;12;16;20];
  
  % Allocate memory for population and new population variables
  pheno_len = size(ub, 1); 
  pop_pheno = zeros(pheno_len, mu);
  pop_geno = cell(pheno_len, mu);   
  power_loss = zeros(1, mu);  
  Pnew_pheno = zeros(pheno_len, mu);  
  Pnew_geno = cell(pheno_len, mu);
  
  
  % Load variables of the experiments
  load('para119.mat')
  
  % Add path of matpower4.1
  addpath('matpower4.1')

  % Statistics administration
  evalcount = 0;
  histf = zeros(1, evalbudget);

  % Initialize population
  for it = 1:mu 
    while valid_119(pop_pheno(:,it)) == 0
      % Generate random individual, decode to phenotype, and evaluate
      for itP = 1:pheno_len
        pop_pheno(itP,it) = randi(ub(itP), 1);
      end
    end
    % Change to bit string for genotype
    pop_geno(:,it) = cellstr(dec2bin(pop_pheno(:, it), 5)); % need at least 5 bits force for maximum integer; Note: Genotype evolution can give back invalid individuals
    % calculate corresponding power loss
    power_loss(it) = calculation_119(pop_pheno(:,it)); 
  end
  
  % Statistics administration
  evalcount = evalcount + 1;
  fopt = min(power_loss);   
  histf(evalcount) = fopt;
  
  % Evolution loop
  while evalcount < evalbudget
    % Remember the best score for elitist step
    [~, eliteindex] = min(power_loss);
    elitePheno = pop_pheno(:,eliteindex);
    eliteGeno = pop_geno(:,eliteindex);
    elitePower = power_loss(eliteindex);
    
    %% Generate new population (crossover, mutation)
    for itPop = 1:mu
      % Tournament selection step
      competitors = randperm(mu, k_tourney); % pick k_tourney different individuals
      [~, sorted] = sort(power_loss); % Sort them on power_loss
      competitors_sorted = intersect(sorted, competitors, 'stable');
      
      % find winner of tournament
      winner = competitors_sorted(1); % Default to fittest if nothing else found
      for itWin = 1:length(competitors_sorted)
        if (rand < pt*((1-pt)^(itWin-1)))
          winner = competitors_sorted(itWin);
          break
        end
      end
      
      % Select the first parent from pop_geno
      p1 = pop_geno(:,winner);

      % Crossover step
      if (rand() < pc)
        % Second tournament selection step to find second parent for
        % crossover
        competitors = randperm(mu, k_tourney); % pick k_tourney different chromosomes
        [~, sorted] = sort(power_loss); % Sort them on power_loss
        competitors_sorted = intersect(sorted, competitors, 'stable');
        % throw away the foregoing winner however exact duplicates are
        % allowed
        competitors_sorted = competitors_sorted(competitors_sorted~=winner); 

        % find winner of tournament chromosome
        winner = competitors_sorted(1); % Default to highest if nothing else found
        for itWin = 1:length(competitors_sorted)
          if (rand < pt*((1-pt)^(itWin-1)))
            winner = competitors_sorted(itWin);
            break
          end
        end
        p2 = pop_geno(:,winner);% Select the second parent from pop_geno
        
        % n point crossover at random points
        cross_point = sort(randperm(pheno_len, npoint));
        % take into account last and first element for for loop
        cross_point = [1, cross_point, pheno_len];
        % initialize variables
        child = cell(pheno_len, 1); % num2cell for bit strings
        usep1 = true;
        % do crossover
        for position = 1:(length(cross_point)-1)
          if usep1 == true
            child(cross_point(position):cross_point(position+1)) =...
                  p1(cross_point(position):cross_point(position+1));
          elseif usep1 == false
            child(cross_point(position):cross_point(position+1)) =...
                  p2(cross_point(position):cross_point(position+1));
          end
          usep1 = not(usep1); % use p1 and p2 alternately
        end
        % New individual is the crossover child
        Pnew_geno(:, itPop) = child; 
      else
        Pnew_geno(:, itPop) = p1; % No crossover, copy the selected parent
      end % crossover for loop
      
      % Mutation step
      Pbinary = cell2mat(Pnew_geno(:, itPop));
      for itGeno = 1:pheno_len
        for itBit = 1:size(Pbinary, 2)
          % Probability to mutate
          if (rand() < pm)
            % for comparison if 1 or 0 change from char to integer
            valueBit = str2num(Pbinary(itGeno, itBit));
            if valueBit == 1
              Pbinary(itGeno, itBit) = num2str(0);
            elseif valueBit == 0
              Pbinary(itGeno, itBit) = num2str(1);
            end
          end
        end
      end
      % convert it back to a cell array
      Pnew_geno(:, itPop) = cellstr(Pbinary);
      Pnew_pheno(:, itPop) = bin2dec(Pbinary);
      
      % For the new phenotype population repair if integer value larger
      % than corresponding upperbound (ub) with random integer, update pheno and geno!
      for itPheno = 1:pheno_len
        if Pnew_pheno(itPheno, itPop) > ub(itPheno)
          Pnew_pheno(itPheno, itPop) = randi(ub(itPheno));
          Pnew_geno(itPheno, itPop) = cellstr(dec2bin(Pnew_pheno(itPheno, itPop), 5));
        end
      end
    end % end for loop crossover and mutation

    %% evaluate, apply elitism and overwrite with new population
    % Elitism step to keep the best generation
    for itPop = 1:mu
      % Evaluate if valid and overwrite old population value
      % otherwise if not valid keep old population individuals 
      % after wards calculate power loss of individual
      if valid_119(Pnew_pheno(:,itPop)) == 1 
        power_loss(itPop) = calculation_119(Pnew_pheno(:,itPop));
        pop_pheno(:,itPop) = Pnew_pheno(:,itPop);
        pop_geno(:,itPop) = Pnew_geno(:,itPop);
      end
    end

    
    % applying elitisme, overwrite highest power loss individual
    [~, pos] = max(power_loss);
    pop_pheno(:,pos) = elitePheno;
    pop_geno(:,pos) = eliteGeno;
    power_loss(pos) = elitePower;

    % Statistics administration
    [fopt, optindex] = min(power_loss);

    aopt = pop_pheno(:,optindex);
    for itPop = 1:mu
      evalcount = evalcount + 1;
      histf(evalcount) = fopt;
    end
  end
end