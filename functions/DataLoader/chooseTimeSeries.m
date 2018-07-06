function [data]=chooseTimeSeries(data,varargin)
%CHOOSETIMESERIES Request the user to select a time series subset
%
%   SYNOPSIS:
%     [data]=CHOOSETIMESERIES(data, varargin)
%
%   INPUT:
%      data         - structure (required)
%                     data must contain three fields :
%
%                         'timestamps' is a 1�N cell array
%                         each cell is a M_ix1 real array
%
%                         'values' is a 1�N cell array
%                         each cell is a M_ix1 real array
%
%                         'labels' is a 1�N cell array
%                         each cell is a character array
%
%                   N: number of time series
%                   M_i: number of samples of time series i
%
%      isOutputFile - logical (optional)
%                     if true, save the data in a DATA_*.mat Matlab file
%                     default: false
%
%      isPlot       - logical (optional)
%                     if true, plot data
%                     default: false
%
%   OUTPUT:
%      data         - structure
%                     fields of data are timestamps, values, labels
%
%   DESCRIPTION:
%      CHOOSETIMESERIES requests user to select  a subset of time series
%      from full data structure
%      CHOOSETIMESERIES replace/overwrite input data structure
%
%   EXAMPLES:
%      [data] = CHOOSETIMESERIES(data)
%      [data] = CHOOSETIMESERIES(data, 'isPlot', true)
%      [data] = CHOOSETIMESERIES(data, 'isPlot', true, 'isOutputfile', true)
%
%
%   EXTERNAL FUNCTIONS CALLED:
%      verificationDataStructure, displayData
%
%   See also VERIFICATIONDATASTRUCTURE, DETECTOVERLAP,
%   MERGETIMESTEPVECTORS, DISPLAYDATA


%   AUTHORS:
%      Ianis Gaudot, Luong Ha Nguyen, James-A Goulet
%
%      Email: <james.goulet@polymtl.ca>
%      Website: <http://www.polymtl.ca/expertises/goulet-james-alexandre>
%
%
%   MATLAB VERSION:
%      Tested on 9.1.0.441655 (R2016b)
%
%   DATE CREATED:
%       April 12, 2018
%
%   DATE LAST UPDATE:
%       April 13, 2018

%--------------------BEGIN CODE ----------------------

%% Get arguments passed to the function and proceed to some verifications

p = inputParser;
defaultisOutputFile = false;
defaultisPlot = false;

addRequired(p,'data', @isstruct );
addParameter(p,'isOutputFile',defaultisOutputFile,@islogical);
addParameter(p,'isPlot',defaultisPlot,@islogical);

parse(p,data, varargin{:} );

data=p.Results.data;
isOutputFile=p.Results.isOutputFile;
isPlot=p.Results.isPlot;

% define global variable for user's answers from input file
global isAnswersFromFile AnswersFromFile AnswersIndex

% Validation of structure data
isValid = verificationDataStructure(data);
if ~isValid
    disp(' ')
    disp('ERROR: Unable to read the data from the structure.')
    disp(' ')
    return
end

%% Display data on screen
displayData(data)

% Get number of time series in dataset
numberOfTimeSeries = length(data.values);

%% Request the user to choose some time series
while(1)
    fprintf('- Choose the time series to process (e.g [1 3 4]) : \n');
    if isAnswersFromFile
        chosen_ts=eval(char(AnswersFromFile{1}(AnswersIndex)));
        disp(['     ', num2str(chosen_ts) ])
    else
        chosen_ts = input('     choice >> ');
    end
    if isempty(chosen_ts)
        disp(' ')
        disp('%%%%%%%%%%%%%%%%%%%%%%%%% > HELP < %%%%%%%%%%%%%%%%%%%%%%%%')
        disp(' ')
        disp(' Choose among the time series.')
        fprintf([' The raw data, time steps and missing data for each ' ...
            'time series can be visualized in the PDF file.'])
        disp(' ')
        disp('%%%%%%%%%%%%%%%%%%%%%%%%% > HELP < %%%%%%%%%%%%%%%%%%%%%%%%')
        disp(' ')
        continue
    elseif ischar(chosen_ts) || any(mod(chosen_ts,1)) || ...
            ~isempty(chosen_ts(chosen_ts<1))
        disp('     wrong input -> should be positive integers')
        continue
    elseif length(chosen_ts) > numberOfTimeSeries
        fprintf(['     wrong input -> number of chosen time series ' ...
            '> number of time series available (%d) \n'], ...
            numberOfTimeSeries  )
        continue
    elseif length(chosen_ts) ~= length(unique(chosen_ts))
        fprintf(['     wrong input -> a same time series' ...
            'cannot be chosen twice.'])
        continue
    elseif ~isempty(chosen_ts(chosen_ts> numberOfTimeSeries))
        disp(['     wrong input -> at least one time series index' ...
            'is out of range.'])
        continue
    else
        
        break
    end
end

% Increment global variable to read next answer when required
AnswersIndex = AnswersIndex + 1;

%% Remove unselected time series from data structure

data.timestamps = data.timestamps(chosen_ts);
data.values = data.values(chosen_ts);
data.labels = data.labels(chosen_ts);

%% Display data on screen
displayData(data)

%% Plot
if isPlot
    plotDataAvailability(data, 'isSaveFigure', false)
end

%% Save in binary DATA_*.mat file
if isOutputFile
    saveDataBinary(data, 'FilePath','processed_data')
end
%--------------------END CODE ------------------------
end