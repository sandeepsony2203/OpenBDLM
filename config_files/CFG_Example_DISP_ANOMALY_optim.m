%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    OpenBDLM configuration file                          %
%          Autogenerated by OpenBDLM on 19-Oct-2018 16:18:08              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% A - Project name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
misc.ProjectName='Example_DISP_ANOMALY_optim';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% B - Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat=load('DATA_Example_DISP_ANOMALY_optim.mat'); 
data.values=dat.values;
data.timestamps=dat.timestamps;
data.labels={'DISP'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% C - Model structure 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Components reference numbers
% 11: Local level
% 12: Local trend
% 13: Local acceleration
% 21: Local level compatible with local trend
% 22: Local level compatible with local acceleration
% 23: Local trend compatible with local acceleration
% 31: Periodic
% 41: Autoregressive
% 51: Kernel regression
% 61: Level Intervention

% Model components
% Model 1
model.components.block{1}={[23 31 41 ] };
% Model 2
model.components.block{2}={[13 31 41 ] };

% Model component constrains | Take the same  parameter as model class #1
model.components.const{2}={[0 1 1 ] };
 
% Model inter-components dependence | {[components form dataset_i depends on components from  dataset_j]_i,[...]}
model.components.ic={[ ] };


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% D - Model parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
model.param_properties={
     % #1           #2             #3      #4    #5               #6           #7       #8              #9              #10
     % Param name   Block name     Model   Obs   Bound            Prior        Mean     Std             Values          Ref
     '\sigma_w',   'TcA',          '1',   '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0,              1      %#1   
     'p',          'PD1',          '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            365.2422,       2      %#2   
     '\sigma_w',   'PD1',          '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0,              3      %#3   
     '\phi',       'AR',           '1',   '1',   [0  1      ],    'N/A',       NaN,     NaN,            0.75,           4      %#4   
     '\sigma_w',   'AR',           '1',   '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0.21343,        5      %#5   
     '\sigma_v',   '',             '1',   '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0.10671,        6      %#6   
     '\sigma_w',   'LA',           '2',   '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0.0012159,      7      %#7   
     '\sigma_v',   '',             '2',   '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0.10671,        8      %#8   
     '\sigma_w',   'TcA',          '12',  '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            8.1224e-06,     9      %#9   
     '\sigma_w',   'LA',           '21',  '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            1.5018e-05,     10     %#10  
     'Z(11)',      '',             '11',  '',    [0  1      ],    'N/A',       NaN,     NaN,            0.99997,        11     %#11  
     'Z(22)',      '',             '22',  '',    [0  1      ],    'N/A',       NaN,     NaN,            0.99957,        12     %#12  
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% E - Initial states values 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial hidden states mean for model 1:
model.initX{ 1 }=[	-9.43 	-0.0109	-5.03E-09	1.08  	-0.00634	-0.548]';

% Initial hidden states variance for model 1: 
model.initV{ 1 }=diag([ 	0.139 	0.000877	2.26  	0.00224	0.00105	0.32   ]);

% Initial probability for model 1
model.initS{1}=[0.997 ];

% Initial hidden states mean for model 2:
model.initX{ 2 }=[	-9.53 	0.102 	-0.0599	1.08  	-0.00636	-0.482]';

% Initial hidden states variance for model 2: 
model.initV{ 2 }=diag([ 	0.674 	0.418 	0.803 	0.00224	0.00105	0.759  ]);

% Initial probability for model 2
model.initS{2}=[0.00279];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% F - Options 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
misc.options.NaNThreshold=100;
misc.options.Tolerance=1e-06;
misc.options.trainingPeriod=[1  Inf];
misc.options.isParallel=false;
misc.options.maxIterations=100;
misc.options.maxTime=60;
misc.options.isMAP=false;
misc.options.isPredCap=false;
misc.options.isLaplaceApprox=false;
misc.options.isMute=false;
misc.options.NRLevelsLambdaRef=4;
misc.options.NRTerminationTolerance=1e-07;
misc.options.MethodStateEstimation='kalman';
misc.options.MaxSizeEstimation=100;
misc.options.DataPercent=100;
misc.options.Seed=12345;
misc.options.FigurePosition=[100   100  1300   270];
misc.options.isSecondaryPlot=false;
misc.options.Subsample=1;
misc.options.Linewidth=3;
misc.options.ndivx=4;
misc.options.ndivy=3;
misc.options.Xaxis_lag=0;
misc.options.isExportTEX=false;
misc.options.isExportPNG=false;
misc.options.isExportPDF=false;

