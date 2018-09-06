%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    OpenBDLM configuration file                          %
%          Autogenerated by OpenBDLM on 05-Sep-2018 18:41:42              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% A - Project name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
misc.ProjectName='CTL_003';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% B - Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dat=load('DATA_CTL_003.mat'); 
data.values=dat.values;
data.timestamps=dat.timestamps;
data.labels={'TS01'};

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
model.components.block{1}={[21 41 51 ] };
% Model 2
model.components.block{2}={[12 41 51 ] };

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
     '\sigma_w',   'LcT',          '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            1e-07,          1      %#1   
     '\phi',       'AR',           '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0.75,           2      %#2   
     '\sigma_w',   'AR',           '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0.01,           3      %#3   
     '\ell',       'KR',           '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0.5,            4      %#4   
     'p',          'KR',           '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            365.2422,       5      %#5   
     '\sigma_w',   'KR',           '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0,              6      %#6   
     '\sigma_hw',  'KR',           '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0,              7      %#7   
     '\sigma_v',   '',             '1',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0.01,           8      %#8   
     '\sigma_w',   'LT',           '2',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            1e-07,          9      %#9   
     '\sigma_v',   '',             '2',   '1',   [NaN  NaN  ],    'N/A',       NaN,     NaN,            0.01,           10     %#10  
     '\sigma_w',   'LcT',          '12',  '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0.0001,         11     %#11  
     '\sigma_w',   'LT',           '21',  '1',   [0  Inf    ],    'N/A',       NaN,     NaN,            0.0001,         12     %#12  
     'Z(11)',      '',             '11',  '',    [0  1      ],    'N/A',       NaN,     NaN,            0.99973,        13     %#13  
     'Z(22)',      '',             '22',  '',    [0  1      ],    'N/A',       NaN,     NaN,            0.99973,        14     %#14  
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% E - Initial states values 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial hidden states mean for model 1:
model.initX{ 1 }=[	10    	0     	0     	2.01  	-0.978	1.66  	1.73  	-1.92 	0.231 	0.372 	-2.9  	-0.227	0.736 	-1.84 ]';

% Initial hidden states variance for model 1: 
model.initV{ 1 }=diag([ 	0.01  	1E-12 	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01   ]);

% Initial probability for model 1
model.initS{1}=[0.5   ];

% Initial hidden states mean for model 2:
model.initX{ 2 }=[	10    	-0.1  	0     	2.01  	-0.978	1.66  	1.73  	-1.92 	0.231 	0.372 	-2.9  	-0.227	0.736 	-1.84 ]';

% Initial hidden states variance for model 2: 
model.initV{ 2 }=diag([ 	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01  	0.01   ]);

% Initial probability for model 2
model.initS{2}=[0.5   ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% F - Options 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
misc.options.trainingPeriod=[1  2*365];
misc.options.isParallel=true;
misc.options.maxIterations=100;
misc.options.maxTime=60;
misc.options.isMAP=false;
misc.options.isPredCap=false;
misc.options.isLaplaceApprox=false;
misc.options.isMute=false;
misc.options.MethodStateEstimation='kalman';
misc.options.FigurePosition=[100   100  1300   270];
misc.options.isSecondaryPlot=true;
misc.options.Subsample=1;
misc.options.Linewidth=1;
misc.options.ndivx=5;
misc.options.ndivy=3;
misc.options.isExportTEX=false;
misc.options.isExportPNG=false;
misc.options.isExportPDF=false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Custom anomalies :
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
misc.custom_anomalies.start_custom_anomalies=[365];
misc.custom_anomalies.duration_custom_anomalies=[20];
misc.custom_anomalies.amplitude_custom_anomalies=[-0.01];

