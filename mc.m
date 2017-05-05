function [aopt, fopt] = mc(evalbudget)
  % Set upperbounds, taken over from valid_119.m
  ub = [25;17;15;21;18;12;11;16;12;17;20;18;12;16;20]; 
  
  % Load variables of the experiments
  load('para119.mat')
  
  % Add path of matpower4.1
  addpath('matpower4.1')

  % Statistics administration
  evalcount = 0;
  histf = zeros(1, evalbudget);
  
  % Initialize
  max_len = size(ub, 1);
  configuration = zeros(max_len, 1);

  % generate random solution and evalute
  while valid_119(configuration) == 0
    for it = 1:max_len
      configuration(it) = randi(ub(it), 1);
    end
  end 
  fopt = calculation_119(configuration);
  aopt = configuration;
  
  % Statistics administration
  evalcount = evalcount + 1;
  histf(evalcount) = fopt;  
  
  % Loop
  while evalcount < evalbudget
    % Generate random configuration and evaluate
    configurationRand = zeros(max_len, 1);
    for itInd = 1:max_len
      configurationRand(itInd) = randi(ub(itInd), 1);
    end

    
    if valid_119(configurationRand)
      power_loss = calculation_119(configurationRand);
    else
      % if not valid remain with same fopt and save it
      evalcount = evalcount + 1;
      histf(evalcount) = fopt;
      continue
    end
    
    % if new power loss value is lower then lowest power loss calculated
    % replace with new value and record corresponding vector
    if (power_loss < fopt)  
      aopt = configurationRand;  
      fopt = power_loss;    
    end
    
    % Statistics administration
    evalcount = evalcount + 1;
    histf(evalcount) = fopt;
  end
end