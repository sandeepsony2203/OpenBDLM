function [optim]=NR_EM(data, model, misc, varargin)
% INPUTS:
% tolerance_timestep  - Similarity between time-steps. Example
%                       0.041667 = 0.04167. Defaut is 1E-4.
% optim_mode          - Maximum Log-likehood Estimation (MLE). Maximum A
%                       Posteriori (MAP). Defaut is MAP.
% parallel            - True (or 1) corresponding to the utilization of
%                       parallel computing, false (0) otherwise. Defaut is
%                       0.
%
% OUTPUTS:
% optim.parameter_OR_opt   - optimal parameters in original space.
% optim.parameter_TR_opt   - optimal parameters in transformed space.
% optim.covParamTR_matrix  - parameter covariance matrix in transformed
%                            spaced using Laplace Approximation. See
%                            Bayesian Data Analysis (Gelman-2014) for
%                            further details.
%% Defaut values
% tolerance for time step (example: 0.041667 = 0.04167)
tol                 = 1e-4;
misc.optim_mode   = 'MAP';
misc.parallel     = 1;

%% If provided, employ user-specific arguments
args    = varargin;
nargs   = length(varargin);
for n = 1:2:nargs
    switch args{n}
        case 'tolerance_timestep',  tol                 = args{n+1};
        case 'optim_mode',          misc.optim_mode   = args{n+1};
        case 'parallel',            misc.parallel     = args{n+1};
        otherwise, error(['unrecognized argument' args{n}])
    end
end
if ~isfield(misc,'disp_flag')
    disp_flag=1;
end
%% Prior existance ?
% If prior is not assigned, we use MLE for estimating model parameters.
if size(model.param_properties,2)<6
    misc.optim_mode   = 'MLE';
end

%% Resize the dataset according to the chosen training period
% Get timestamp vector
timestamps = data.timestamps;
% Get training period
training_start_idx = day2sampleIndex(misc.trainingPeriod(1), timestamps);
training_end_idx = day2sampleIndex(misc.trainingPeriod(2), timestamps);
% Resize timestamps

data_train.timestamps = timestamps(training_start_idx:training_end_idx);

% Get timestep training vector
[data_train.dt_steps]=computeTimeSteps(data_train.timestamps);
data_train.nb_steps = length(training_start_idx:training_end_idx);

% Compute reference timestep during training
[data_train.dt_ref] = defineReferenceTimeStep(data_train.timestamps);

%Define time step vector
data_train.dt_steps           = [data_train.dt_ref;data_train.dt_steps];
% data.dt_ref                   = data_train.dt_ref ;
% data.dt_steps(1)              = data.dt_ref;

%Get data values 
DataValues = data.values;
% Resize data values
for i=1:size(data.values,2)
    data_train.values(:,i) = DataValues(training_start_idx:training_end_idx,i);
end

%% Identify parameters to be optimized
parameter_search_idx    = find(~all(isnan(reshape([model.param_properties{:,5}],2,size(model.param_properties,1))'),2));
nb_param                = length(parameter_search_idx);

%% Initialize transformed model parameters
parameter_OR            = model.parameter;
parameter_TR            = zeros(length(model.parameter),1);
transfFunc.TR           = cell(1,nb_param);
transfFunc.InvTR        = cell(1,nb_param);
transfFunc.gradTR2OR    = cell(1,nb_param);
for i = 1 : nb_param
    idx                 = parameter_search_idx(i);
    [transfFunc.TR{i},transfFunc.InvTR{i},transfFunc.gradTR2OR{i},~] = parameter_transformation_fct(model,idx);
    parameter_TR(idx)   = transfFunc.TR{i}(parameter_OR(idx));
end
% parameterTR_ref = parameter_TR;
model.parameterTR   = parameter_TR;
%% Analysis parameters
nb_levels_lambda_ref    = 4;
convergence_tolerance   = 1E-7;

if disp_flag==1
    %% Diaplay analysis parameters
    disp('----------------------------------------------------------------------------------------------')
    disp('Estimate the parameters for the Bayesian Dynamic Linear Model')
    disp('----------------------------------------------------------------------------------------------')
    disp(' ')
    disp('    \\start Newton-Raphson maximization algorithm (finite difference method)')
    disp(' ')
    disp(['      Training period:                                       ' num2str(misc.trainingPeriod(1)) '-' num2str(misc.trainingPeriod(2)) ' [days]'])
    disp(['      Maximal number of iteration:                           ' num2str(misc.iteration_limit_calibration)])
    disp(['      Total time limit for calibration:                      ' num2str(misc.time_limit_calibration) ' [min]'])
    disp(['      Convergence criterion:                                 ' num2str(convergence_tolerance) '*LL'])
    disp(['      Nb. of search levels for \lambda:                      ' num2str(nb_levels_lambda_ref) '*2'])
    disp(' ')
    disp('    ...in progress')
    disp(' ')
end

%% Matrices & parameter initilization
hessian_fail_hist        = zeros(1,numel(parameter_search_idx));
optimization_fail        = zeros(1,numel(parameter_search_idx));
converged                = zeros(1,numel(parameter_search_idx));
dll                      = 1E6*ones(1,numel(parameter_search_idx));
grad_p_TR                = zeros(size(parameter_OR));
hessian_p_TR             = zeros(size(parameter_OR));
std_p                    = zeros(size(parameter_OR));
std_p_TR                 = abs(parameter_TR);
delta_grad               = 1E-3*ones(size(parameter_OR));
%% Log-likelihood initialization
[logpdf_0, ~, ~,~] = logPosteriorPE(data_train, model, misc, 'getlogpdf', 1);
if isinf(logpdf_0)
    disp('warning LL0=-inf | NR_EM.m')
end
if disp_flag==1
    disp(['           Initial LL: ' num2str(logpdf_0)])
end
name_idx_1='';
name_idx_2='';
for i=parameter_search_idx'
    name_p1{i}=[model.param_properties{i,1}];
    if ~isempty(model.param_properties{i,4})
        temp=model.param_properties{i,4}(1);
    else
        temp='';
    end
    name_p2{i}=[model.param_properties{i,2}, '|M', model.param_properties{i,3},'|',temp];
    name_idx_1=[name_idx_1  name_p1{i} repmat(' ',[1,15-length(name_p1{i})]) ' '];
    name_idx_2=[name_idx_2  name_p2{i} repmat(' ',[1,15-length(name_p2{i})]) ' '];
end
if disp_flag==1
    disp(['                       ' name_idx_2])
    disp(['      parameter names: ' name_idx_1])
    fprintf(['       initial values: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR)])],parameter_OR(parameter_search_idx))
end

%% NR Optimization loops
tic; % time counter initialization
time_loop=0;
search_loop=1;
while and(search_loop<=misc.iteration_limit_calibration, time_loop<(misc.time_limit_calibration*60))
    if disp_flag==1
        disp(' ')
    end
    parameter_OR_ref = parameter_OR;
    parameter_TR_ref = parameter_TR;
    %% Select the parameter which previously led to the highest change in LL
    rand_sample = rand;
    dll_cumsum  = cumsum(dll)/sum(dll);
    dll_rank    = dll_cumsum-rand_sample;
    dll_rank(dll_rank<0) = inf;
    % Remove the parameters that have small impact on log-likelihood
    dll_rank(hessian_fail_hist>10) = Inf;
    if all(dll_rank == Inf)
        param_idx = find(~converged,1,'first');
    else
        param_idx = find((dll_cumsum-rand_sample)==min(dll_rank),1,'first');
    end
    param_idx_loop = parameter_search_idx(param_idx);
    param          = parameter_OR_ref(param_idx_loop);
    param_TR       = parameter_TR_ref(param_idx_loop);
    if disp_flag == 1
        disp('--------------------------')
        disp(['    Loop #' num2str(search_loop) ' : ' [name_p2{param_idx_loop} '|' name_p1{param_idx_loop}]])
    end
    H_test       = 1;
    loop_count   = 1;
    skip_loop_H  = 0;
    hessian_fail = 0;
    % loop until the hessian can be calculated
    while H_test
        loop_count=loop_count +1;
        if loop_count >5 || hessian_fail
            if disp_flag==1
                disp('           Warning:>5 failed attempts to compute the Hessian')
            end
            skip_loop_H = 1;
            hessian_fail_hist(param_idx)        = hessian_fail_hist(param_idx)+1;
            parameter_OR(param_idx_loop)        = parameter_OR_ref(param_idx_loop);
            parameter_TR(param_idx_loop)        = parameter_TR_ref(param_idx_loop);
            if hessian_fail_hist(param_idx)>3
                if disp_flag == 1
                    disp('           Warning: 3nd discontinued fails to compute the Hessian  -> converged=1')
                end
                converged(param_idx) = 1;
            end
            dll(param_idx) = abs(convergence_tolerance*logpdf_0);
            break
        end
        
        model.parameter   = parameter_OR;
        model.parameterTR = parameter_TR;
        [~, GlogpdfTR_loop, HlogpdfTR_loop, delta_grad_loop] = logPosteriorPE(data_train, model, misc,...
            'paramTR_index',param_idx_loop,...
            'stepSize4grad',delta_grad(param_idx_loop));
        delta_grad(param_idx_loop) = delta_grad_loop;
        if hessian_fail_hist(param_idx) > 0
            hessian_fail_hist(param_idx) = 0;
        end
        if HlogpdfTR_loop < 0
            hessian_p_TR(param_idx_loop) = HlogpdfTR_loop;
            grad_p_TR(param_idx_loop)    = GlogpdfTR_loop;
            delta_p_TR                   = - GlogpdfTR_loop/HlogpdfTR_loop;
            H_test                       = 0;
        elseif HlogpdfTR_loop > 0
            hessian_p_TR(param_idx_loop) = HlogpdfTR_loop;
            grad_p_TR(param_idx_loop)    = GlogpdfTR_loop;
            if model.param_properties{param_idx_loop,5}(1)==0&&model.param_properties{param_idx_loop,5}(2)==inf&&abs(param)<1E-7
                delta_p_TR = sign(GlogpdfTR_loop)*0.25*param_TR;
            else
                %Gradient descent must be used to reach the maxima
                delta_p_TR = 0.1*GlogpdfTR_loop/HlogpdfTR_loop;
            end
            if disp_flag==1
                disp('           Warning: Hessian is positive ')
            end
            H_test = 0;
        elseif isnan(HlogpdfTR_loop)
            H_test       = 1;
            hessian_fail = 1;
        end
    end
    if skip_loop_H ~= 1
        std_p_TR_loop = sqrt(-1/hessian_p_TR(param_idx_loop));
        %Linearized Laplace approximation of parameter standard deviation
        std_p_loop    = abs(transfFunc.gradTR2OR{param_idx}(param_TR))*std_p_TR_loop;
        if hessian_p_TR(param_idx_loop) < 0
            std_p(param_idx_loop)    = std_p_loop;
            std_p_TR(param_idx_loop) = std_p_TR_loop;
        else
            std_p(param_idx_loop)    = NaN;
            std_p_TR(param_idx_loop) = NaN;
        end
        delta_p = transfFunc.InvTR{param_idx}(param_TR+delta_p_TR) - param;
        if disp_flag==1
            disp(['       delta_param: ' num2str(delta_p)])
        end
        try
            %% LL test
            parameter_TR(param_idx_loop) = param_TR + delta_p_TR;
            parameter_OR(param_idx_loop) = transfFunc.InvTR{param_idx}(parameter_TR(param_idx_loop));
            model.parameter              = parameter_OR;
            model.parameterTR            = parameter_TR;
            [logpdf_test, ~, ~,~]        = logPosteriorPE(data_train, model, misc, 'getlogpdf', 1);
        catch err
            logpdf_test = -inf;
        end
        loop_converged = 1;
        delta_p_TR_ref = delta_p_TR;
    else
        % Optimization has failed the actual parameter -> move to next parameter
        loop_converged = 0;
    end
    %% Check the validity of delta_p
    n                = 0;
    reverse          = 0;
    n_ref            = 0;
    nb_levels_lambda = nb_levels_lambda_ref;
    while loop_converged
        n=n+1;
        if logpdf_test>logpdf_0
            loop_converged       = 0;
            converged(param_idx) = and(~isnan(std_p(param_idx_loop)),abs(logpdf_test - logpdf_0)<abs(convergence_tolerance*logpdf_0));
            dll(param_idx)       = logpdf_test - logpdf_0; % Record the change in the log-likelihood
            if dll(param_idx)<abs(convergence_tolerance*logpdf_0)
                if isnan(std_p(param_idx_loop))
                    dll(param_idx) = 10*abs(convergence_tolerance*logpdf_0);
                else
                    dll(param_idx) = abs(convergence_tolerance*logpdf_0);
                end
            end
            logpdf_0                            = logpdf_test;
            parameter_TR_ref(param_idx_loop)    = parameter_TR(param_idx_loop);
            parameter_OR_ref(param_idx_loop)    = parameter_OR(param_idx_loop);
            if disp_flag==1
                disp(['    log-likelihood: ' num2str(logpdf_0)])
                disp(['      param change: ' num2str(param) ' -> ' num2str(parameter_OR(param_idx_loop))])
                disp(' ')
                disp(['                    ' name_idx_2])
                disp(['   parameter names: ' name_idx_1])
                fprintf(['    current values: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR(parameter_search_idx))-1]) '%#-+15.2e\n',...
                    '  current f.o. std: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR(parameter_search_idx))-1]) '%#-+15.2e\n',...
                    '      previous dLL: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR(parameter_search_idx))-1]) '%#-+15.2e\n',...
                    '         converged: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR(parameter_search_idx))-1]) '%#-+15.2e\n'],...
                    parameter_OR(parameter_search_idx),...
                    std_p(parameter_search_idx),...
                    dll,...
                    converged);
                
            end
            optimization_fail=optimization_fail*0;
            
            if converged(param_idx)
                break
            else
                converged(param_idx)=0;
            end
            
        else
            converged(param_idx)=0;
            if n>nb_levels_lambda
                if disp_flag==1
                    disp(' ')
                    disp('      ...optimization loop has failed')
                end
                parameter_OR(param_idx_loop) = parameter_OR_ref(param_idx_loop);
                parameter_TR(param_idx_loop) = parameter_TR_ref(param_idx_loop);
                optimization_fail(param_idx) = optimization_fail(param_idx)+1;
                if optimization_fail(param_idx)>3
                    converged(param_idx) = 1;
                    dll(param_idx)       = abs(convergence_tolerance*logpdf_0);
                else
                    dll(param_idx) = 2*abs(convergence_tolerance*logpdf_0);
                end
                break
            elseif n < nb_levels_lambda
                delta_p_TR  = delta_p_TR/(2^n);
                delta_p     = transfFunc.InvTR{param_idx}(param_TR + delta_p_TR)-param;
                if disp_flag == 1
                    disp(['           Warning: log-likelihood has decreased -> delta_param: ' sprintf('%#-+8.2e',delta_p) ' (delta_p_TR=delta_p_TR/(2^' num2str(n) '))'])
                end
            elseif n == nb_levels_lambda
                if reverse == 0
                    reverse     = 1;
                    n           = n_ref;
                    delta_p_TR  = -delta_p_TR_ref;
                    delta_p     = transfFunc.InvTR{param_idx}(param_TR+delta_p_TR) - param;
                elseif reverse == 1
                    reverse          = 0;
                    n_ref            = n;
                    nb_levels_lambda = 2*nb_levels_lambda_ref;
                    delta_p_TR       = delta_p_TR_ref;
                    delta_p          = transfFunc.InvTR{param_idx}(param_TR+delta_p_TR)-param;
                end
                if disp_flag==1
                    disp(['           Warning: log-likelihood has decreased -> delta_param: ' sprintf('%#-+8.2e',delta_p) ' (delta_p_TR=-delta_p_TR)'])
                end
                
            end
            try
                %% LL test
                parameter_TR(param_idx_loop) = param_TR + delta_p_TR;
                parameter_OR(param_idx_loop) = transfFunc.InvTR{param_idx}(parameter_TR(param_idx_loop));
                model.parameter              = parameter_OR;
                model.parameterTR            = parameter_TR;
                [logpdf_test, ~, ~,~]        = logPosteriorPE(data_train, model, misc,'getlogpdf', 1);
            catch err
                logpdf_test=-inf;
            end
        end
    end
    search_loop=search_loop+1;
    if all(optimization_fail>0)
        if disp_flag==1
            disp(' ')
            disp('          WARNING: the optimization has failed for every parameter')
        end
        break
    elseif all(converged)
        if disp_flag==1
            disp(' ')
            disp('             DONE: the optimization has converged for all parameters')
        end
        break
    end
    time_loop=toc;
end
if disp_flag==1
    if ~or(all(optimization_fail),all(converged))
        disp(' ')
        disp(' ')
        disp(' ')
        if time_loop>(misc.time_limit_calibration*60)
            disp(['          WARNING : the optimization has reached the maximum allowed time (' num2str(misc.time_limit_calibration) ' [min]) without convergence'])
        else
            disp(['          WARNING : the optimization has reached the maximum number of loops (' num2str(misc.iteration_limit_calibration) ') without convergence'])
        end
    end
end

if disp_flag==1
    %% Display final results
    disp(' ')
    disp(' ----------------------')
    disp('    Final results')
    disp(' ----------------------')
    disp(['   log-likelihood: ' num2str(logpdf_0)])
    disp(['                     ' name_idx_2])
    disp(['  parameter names: ' name_idx_1])
    fprintf(['   current values: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR(parameter_search_idx))-1]) '%#-+15.2e\n',...
        ' current f.o. std: ' repmat(['%#-+15.2e' ' '],[1,length(parameter_OR(parameter_search_idx))-1]) '%#-+15.2e\n'],...
        parameter_OR(parameter_search_idx),...
        std_p(parameter_search_idx))
end
%% Outputs
optim.parameter_opt         = parameter_OR;
optim.parameterTR_opt       = parameter_TR;
optim.std_parameter_TR_opt  = std_p;
optim.hessian_p_TR_opt      = hessian_p_TR(parameter_search_idx);
optim.std_parameter_TR_opt  = std_p_TR;
optim.converged             = converged;
optim.search_loop           = search_loop;
optim.log_lik               = logpdf_0;
optim.data                  = data;
optim.data_train            = data_train;
optim.optim_mode            = misc.optim_mode ;
optim.misc                = misc;
% Laplace Approximation
% if all(converged)
%     disp('    Laplace Approximation...')
%     [covParamTR_matrix, hessParamTR_matrix, hessParamOR_matrix] = LaplaceApproximation(data, model, misc,...
%                                                                                    parameter_TR,...
%                                                                                    parameter_OR,...
%                                                                                    transfFunc.gradTR2OR,...
%                                                                                    parameter_search_idx,...
%                                                                                    std_p_TR);
%     optim.covParamTR_matrix     = covParamTR_matrix;
%     optim.hessParamTR_matrix    = hessParamTR_matrix;
%     optim.hessParamOR_matrix    = hessParamOR_matrix;
% end
end

function [covParamTR_matrix, hessParamTR_matrix, hessParamOR_matrix] = LaplaceApproximation(data, model, misc, pTR, pOR, func_gradTR2OR, search_idx, std_p_TR)
if size(model.param_properties,2)>6
    logpriorMu               = [model.param_properties{:,7}]; % mean
    logpriorSig              = [model.param_properties{:,8}]; % standard deviation
    logpriorName             = {model.param_properties{:,6}}; % distribution name
    prior_empty = 0;
else
    prior_empty = 1;
end
nb_param                 = length(search_idx);
gradParamTR_matrix       = zeros(nb_param,nb_param);
hessParanTR_prior_matrix = zeros(nb_param,nb_param);
delta_diff               = 1E-6*ones(nb_param,1);         % stepsize for the nummerical hessian
for p = 1 : nb_param
    idx = search_idx(p);
    gradParamTR_matrix(p,p) = func_gradTR2OR{p}(pTR(idx));
    if prior_empty
        hessParanTR_prior_matrix(p,p) = 0;
    else
        [~, ~, hessParanTR_prior_matrix(p,p)]      = logPriorDistr(pTR(idx), logpriorMu(idx), logpriorSig(idx),'distribution',logpriorName{idx});
    end
    if pOR(idx)<5E-3
        delta_diff(p) = 1E-4;
    end
end

loglikH             = @(p) loglik4hessian (p, data, model, misc, search_idx);
hessParamOR_matrix  = numerical_hessian(pOR(search_idx), loglikH, 'stepSize',delta_diff);
hessParamTR_matrix  = gradParamTR_matrix' * hessParamOR_matrix * gradParamTR_matrix + hessParanTR_prior_matrix;
if ~any(any(isnan(hessParamTR_matrix)))
    covParamTR_matrix   = inv(-hessParamTR_matrix);
    if any(any(diag(covParamTR_matrix<0)))
        if ~any(any(isnan(std_p_TR(search_idx))))
            covParamTR_matrix   = diag(std_p_TR(search_idx).^2);
        else
            disp('Warning: Covariance Matrix cannot compute')
            covParamTR_matrix = NaN(nb_param, nb_param);
        end
    end
end
end

function  LL = loglik4hessian (p, data, model, misc, search_idx)
model.parameter(search_idx) = p;
[~,~,~,~,LL,~,~]            = SKF(data,model,misc);
end
