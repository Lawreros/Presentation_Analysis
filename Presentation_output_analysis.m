% Program to load, process, and plot Presentation .txt files
%
% Requires:
%   .txt files from the 4 MRI_sessions of stimuli and responses
%   .txt files from the 3 Memory_test activity, where participants were
%   tested on what they remembered from the stimuli shown in the MRI,
%   with several new images added to decieve them
%   (Optional) .txt files from the n-back activity
%
%
% Output:
%   Comp_data: a matrix containing the answers given during the Memory_test
%   and whether they were correct
%   Result_data: a matrix containing each picture and which category it
%   falls under
%   n_back_list: Which answers the participant got correct for each type


clear all;
close all;

% Name of file created by MRI_session
encode_list = {...,
    '/data/MRI_session.txt', ...
    '/data/MRI_session2.txt', ...
    '/data/MRI_session3.txt', ...
    '/data/MRI_session4.txt'};

% Name of n-back files ( = 0 if not n-back data)
nbck = 0;
    n_back_list = {'/data/MRI_n-back.txt', ...
    '/data/MRI_n-back2.txt'};

% Name of file created by Memory_test
test_list = {...
    '/data/Memory_test.txt', ...
    '/data/Memory_test2.txt', ...
    '/data/Memory_test3.txt'};

%% ================= END USER INPUT=====================
% Read information from MRI_session
q = 1;
Encode_raw = {};
for z = 1:length(encode_list)
    
fid = fopen(encode_list{z});

% Eliminate header information
for i = 1:6
line = fgetl(fid);
end

% Read in information
i = 1;
while line ~= ""
    M(i,:) = textscan(line, '%d %s %s %s %s %d %d %d %d %d %d', 'Delimiter', '\t');
    line = fgetl(fid);
    i=i+1;
end
Encode_raw = [Encode_raw;M(:,2:6)]; %single out the values we care about (picture name, background, time, answer, etc) and put them into one large table

% Sort throught the data read in from the previous Test file
[r,c] = size(M);
p=1;
for i = 1:r
    if strcmp(M{i,2}{1},'Picture') && strcmp(M{i,3}{1},'fixation')==0   %Go through the chunk of Encoded data and seperate out the Picture, Fixation, and Response prompts
        MRI_data{q,1} = M{i,3}{1};
        MRI_data{q,2} = M{i,4}{1};
        MRI_data{q,3} = M{i,5}{1};
        MRI_data{q,5} = M{i,6};
        q = q+1;
        p = 1;
    elseif strcmp(M{i,3}{1},'fixation') && p == 1       % Don't care about fixations, so remove them
        %q = q+1;
        p = 0;                       % Once it sees fixation, it gets reset to accept the next Picture
    elseif strcmp(M{i,2}{1},'Response') && p == 1
        MRI_data{end,4} = str2double(M{i,3});                       % Universal Time of Response
        MRI_data{end,5} =  str2double(M{i,4}) - MRI_data{end,5};    % Time since Picture was shown
        p = 0;
    else
    end
end
clear M;
end

%% Analyze response time for encoding and create cell array for later plotting/analysis
Response_time{1,1} = 'Self_Object';
Response_time{1,2} = 'Response_Time';
Response_time{1,3} = 'Animacy_Object';
Response_time{1,4} = 'Response_Time';

sfail = {};
afail = {};

q=2;
z=2;
a=0;
b=0;
for i = 1:length(MRI_data)      % Go through the data collected from the MRI Session and determine when the participant failed to answer in time
    
    if strcmp(MRI_data{i,3},'SELF') && isempty(MRI_data{i,4}) == 0      %MRI_data{i,4} is the button that was pressed by the participant for the picture (empty if missed)
        Response_time{q,1} = MRI_data{i,1};
        Response_time{q,2} = MRI_data{i,5};
        q = q+1;
    elseif strcmp(MRI_data{i,3},'ANIMACY') && isempty(MRI_data{i,4}) == 0
        Response_time{z,3} = MRI_data{i,1};
        Response_time{z,4} = MRI_data{i,5};
        z = z+1;
    elseif strcmp(MRI_data{i,3},'SELF') && isempty(MRI_data{i,4}) == 1
        a = a+1;
        sfail{a,1} = MRI_data(i,1);
    elseif strcmp(MRI_data{i,3},'ANIMACY') && isempty(MRI_data{i,4}) == 1
        b = b+1;
        afail{b,1} = MRI_data{i,1};
    else
    end    
end

%Get quick average response time (corrected into seconds)
disp(strcat('Average_Self_Response = ',num2str(mean([Response_time{2:end,2}])/10000),' STD = ',num2str(std(double([Response_time{2:end,2}]))/10000)));
disp(strcat('Missed_Self_Questions = ', num2str(a)));
disp(strcat('Average_Living_Response = ',num2str(mean([Response_time{2:end,4}])/10000),' STD = ',num2str(std(double([Response_time{2:end,4}]))/10000)));
disp(strcat('Missed_Living_Questions = ', num2str(b)));

clear a b q z;
%% Read information from Memory_test
q = 1;

for z = 1:length(test_list)    
fid1 = fopen(test_list{z});

% Eliminate header information
for i = 1:6
line = fgetl(fid1);
end
clear T;

% Read in information
i = 1;
while line ~= ""
    T(i,:) = textscan(line, '%d %s %s %d %d %d %d %d %d %s %s %d', 'Delimiter', '\t');
    line = fgetl(fid1);
    i=i+1;
end

[r,c] = size(T);
p=1;
i=1;

% Go through raw Test answers and organize it into Test_data
while i < r

        Test_data{q,1} = T{i,3}{1};
     	Test_data{q,2} = str2double(T{i+1,3}{1});
        Test_data{q,3} = T{i+1,4}-T{i,4};
	if str2double(T{i+1,3}{1}) == 2
        fid = fopen(encode_list{z});
		Test_data{q,4} = NaN;
        i = i+2;
        q = q+1;
	else
		% Background
		if strcmp(T{i+2,3}{1},'garden') && str2double(T{i+3,3}{1}) == 1
			Test_data{q,4} = 'garden';
		elseif strcmp(T{i+2,3}{1},'garden') && str2double(T{i+3,3}{1}) == 3
			Test_data{q,4} = 'beach';
		end
	
		Test_data{q,5} = T{i+3,4} - T{i+2,4};

		% Question
		if strcmp(T{i+4,3}{1},'smile') && str2double(T{i+5,3}{1}) == 1
			Test_data{q,6} = 'smile';
		elseif strcmp(T{i+4,3}{1},'smile') && str2double(T{i+5,3}{1}) == 3
			Test_data{q,6} = 'leaf';
		end

		Test_data{q,7} = T{i+5,4} - T{i+4,4};

		q = q+1;
		i = i+6;

	end

end

end

clear c fid fid1 i line p z r test_list T;
%% Compare both data sets, 

for i = 1:length(Test_data)
    
    if isempty(find(strcmp(MRI_data, Test_data{i,1}))) % If the picture was a new image in the test not seen in the MRI
        
        Comp_data{i,1} = Test_data{i,1};
        if Test_data{i,2} == 1              % If the answer they gave on the test was 1, then they said they remembered it (incorrect)
            Comp_data{i,2} = 'Remember';
            Comp_data{i,3} = 0;
        elseif Test_data{i,2} == 2         % If the answer they gave on the test was 0, then they said it was new (correct)
            Comp_data{i,2} = 'New';
            Comp_data{i,3} = 1;
        else
            Comp_data{i,2} = 'Familiar';    % If the answer they gave on the test was 2, then they said it was familiar (incorrect)
            Comp_data{i,3} = 0;
        end
        
        Comp_data{i,4} = NaN;               % No matter what they say on a new image with reguards to background or question, they will be wrong
        Comp_data{i,5} = NaN;
        Comp_data{i,6} = NaN;
        Comp_data{i,7} = NaN;
        
        
    else            %If the picture was seen during the MRI session
        pl = find(strcmp(MRI_data, Test_data{i,1}));
        pl = pl(1);
        %Recognition
        Comp_data{i,1} = Test_data{i,1}; % Similar to above, except the image was seen, so Remember and Familiar are correct answers
        if Test_data{i,2} == 1
            Comp_data{i,2} = 'Remember';
            Comp_data{i,3} = 1;
        elseif Test_data{i,2} == 2
            Comp_data{i,2} = 'New';
            Comp_data{i,3} = 0;
        else
            Comp_data{i,2} = 'Familiar';
            Comp_data{i,3} = 1;
        end
        
        %Background
        Comp_data{i,4} = Test_data{i,4};        % Check to see if the background image seen in the MRI matches their answer on the Test
        if strcmp(Test_data{i,4},MRI_data{pl,2})
            Comp_data{i,5} = 1; % Match
        else
            Comp_data{i,5} = 0; % Don't
        end
        
        %Question
        
        if isnan(Test_data{i,6})
            Comp_data{i,6} = NaN;
        else
            Comp_data{i,6} = Test_data{i,6};
        end
        
                % See if question seen in the MRI matches their answer
        if strcmp(Test_data{i,6},'smile') && strcmp(MRI_data{pl,3}, 'SELF')
            Comp_data{i,7} = 1; % match
        elseif strcmp(Test_data{i,6},'leaf') && strcmp(MRI_data{pl,3}, 'ANIMACY')
            Comp_data{i,7} = 1; % match
        else
            Comp_data{i,7} = 0; % don't
        end
    end
    
end


%% Data analysis
% Create a matrix of the various clasifications associated with each picture
% Note: these definitions could be made clearer, in summary, the
% participant is shown in the MRI a picture with a given background and
% asked either the self or living question. Then on the test they are asked
% if they remember the image, which background it had, and what question it had 


Result_data{1,1} = {'Object'};
Result_data{1,2} = {'Hit_self'};            % Said Remember or Familiar correctly for a picture shown with the "self" question
Result_data{1,3} = {'Hit_living'};          % " " living question
Result_data{1,4} = {'False_Alarm_Remember'};   % Said Remember on a New image
Result_data{1,5} = {'False_Alarm_Familiar'};         % Said Familiar on a new image
Result_data{1,6} = {'Correct_Rejection'};       % Said new on a new image
Result_data{1,7} = {'Miss_self'};               % Said new for an image that wasn't new that was shown with the self question
Result_data{1,8} = {'Miss_living'};             % " " living question
Result_data{1,9} = {'Correct_Remember_self'};     % Correctly said Remember on a picture shown with the "self" question
Result_data{1,10} = {'Correct_Remember_living'};    % " " living question
Result_data{1,11} = {'Correct_Familiar_self'};      % Correctly said Familiar on a picture shown with the "self" question
Result_data{1,12} = {'Correct_Familiar_living'};    % " " living question
Result_data{1,13} = {'Correct_Background_Remember_self'};       % Correctly picked the background for an image they were asked the "self" question with and correctly said "Remember"
Result_data{1,14} = {'Correct_Background_Remember_living'};     % " " living question " "
Result_data{1,15} = {'Correct_Background_Familiar_self'};       % Correctly picked the background for an image they were asked the "self" question with and correctly said "Familiar"
Result_data{1,16} = {'Correct_Background_Familiar_living'};     % " " living question " "
Result_data{1,17} = {'Correct_Question_Remember_self'};         % Correctly picked the "self" question on an image they correctly said they Remembered
Result_data{1,18} = {'Correct_Question_Remember_living'};       % Correctly picked the "living" question on an image they correctly said they Remembered
Result_data{1,19} = {'Correct_Question_Familiar_self'};         % Correctly picked the "self" question on an image they correctly said was Familiar
Result_data{1,20} = {'Correct_Question_Familiar_living'};       % " " living question " "
Result_data{1,21} = {'All_Correct_Remember_self'};              % Correctly Remembered the image, the background, and the "self" question
Result_data{1,22} = {'All_Correct_Remember_living'};            % " " livng question
Result_data{1,23} = {'All_Correct_Familiar_self'};              % Correctly said the image was Familiar, got the background, and the "self" question
Result_data{1,24} = {'All_Correct_Familiar_living'};            % " " living question

% Creates a matrix of Comp_data where each picture is checked to see if it
% meets any of the above requirements

for i = 1:length(Comp_data)
    % Object
    Result_data{i+1,1} = Comp_data{i,1};
    pl = find(strcmp(MRI_data, Comp_data{i,1}));
    if length(pl) > 1
        pl = pl(1);
    end
    
    
    % Hit_self & Hit_living
    if (strcmp(Comp_data{i,2},'Remember') || strcmp(Comp_data{i,2}, 'Familiar')) && Comp_data{i,3} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,2} = 1;
            Result_data{i+1,3} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,2} = 0;
            Result_data{i+1,3} = 1;
        else
            Result_data{i+1,2} = 0;
            Result_data{i+1,3} = 0;
        end
    else
        Result_data{i+1,2} = 0;
        Result_data{i+1,3} = 0;
    end
    
    % False_Alarm_Remember
    if strcmp(Comp_data{i,2},'Remember') && Comp_data{i,3} == 0
        Result_data{i+1,4} = 1;
    else
        Result_data{i+1,4} = 0;
    end
    
    
    % False_Alarm_Familiar
    if strcmp(Comp_data{i,2},'Familiar') && Comp_data{i,3} == 0
        Result_data{i+1,5} = 1;
    else
        Result_data{i+1,5} = 0;
    end
    
    % Correct_Rejection
    if strcmp(Comp_data{i,2},'New') && Comp_data{i,3} == 1
        Result_data{i+1,6} = 1;
    else
        Result_data{i+1,6} = 0;
    end
    
    % Miss_Self & Miss_living
    if strcmp(Comp_data{i,2},'New') && Comp_data{i,3} == 0
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,7} = 1;
            Result_data{i+1,8} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,7} = 0;
            Result_data{i+1,8} = 1;
        else
            Result_data{i+1,7} = 0;
            Result_data{i+1,8} = 0;
        end
    else
        Result_data{i+1,7} = 0;
        Result_data{i+1,8} = 0;
        
    end
    
    
    % Number_Remember_self & living
     if strcmp(Comp_data{i,2},'Remember') && Comp_data{i,3} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,9} = 1;
            Result_data{i+1,10} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,9} = 0;
            Result_data{i+1,10} = 1;
        else
            Result_data{i+1,9} = 0;
            Result_data{i+1,10} = 0;
        end
    else
        Result_data{i+1,9} = 0;
        Result_data{i+1,10} = 0;
     end
    
    
    % Number_Familiar_self & living
    if strcmp(Comp_data{i,2},'Familiar') && Comp_data{i,3} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,11} = 1;
            Result_data{i+1,12} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,11} = 0;
            Result_data{i+1,12} = 1;
        else
            Result_data{i+1,11} = 0;
            Result_data{i+1,12} = 0;
        end
    else
        Result_data{i+1,11} = 0;
        Result_data{i+1,12} = 0;
    end
    
    
    % Correct_Background_Remember_self & living
    if strcmp(Comp_data{i,2},'Remember') && Comp_data{i,3} == 1 && Comp_data{i,5} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,13} = 1;
            Result_data{i+1,14} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,13} = 0;
            Result_data{i+1,14} = 1;
        else
            Result_data{i+1,13} = 0;
            Result_data{i+1,14} = 0;
        end
    else
        Result_data{i+1,13} = 0;
        Result_data{i+1,14} = 0;
    end
    
    
    % Correct_Background_Familiar_self & living
    if strcmp(Comp_data{i,2},'Familiar') && Comp_data{i,3} == 1 && Comp_data{i,5} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,15} = 1;
            Result_data{i+1,16} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,15} = 0;
            Result_data{i+1,16} = 1;
        else
            Result_data{i+1,15} = 0;
            Result_data{i+1,16} = 0;
        end
    else
        Result_data{i+1,15} = 0;
        Result_data{i+1,16} = 0;
    end
        
    
    % Correct_Question_Remember_self & living
    if strcmp(Comp_data{i,2},'Remember') && Comp_data{i,3} == 1 && Comp_data{i,7} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,17} = 1;
            Result_data{i+1,18} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,17} = 0;
            Result_data{i+1,18} = 1;
        else
            Result_data{i+1,17} = 0;
            Result_data{i+1,18} = 0;
        end
    else
        Result_data{i+1,17} = 0;
        Result_data{i+1,18} = 0;
    end
    
    
    % Correct_Question_Familiar_self & living
    if strcmp(Comp_data{i,2},'Familiar') && Comp_data{i,3} == 1 && Comp_data{i,7} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,19} = 1;
            Result_data{i+1,20} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,19} = 0;
            Result_data{i+1,20} = 1;
        else
            Result_data{i+1,19} = 0;
            Result_data{i+1,20} = 0;
        end
    else
        Result_data{i+1,19} = 0;
        Result_data{i+1,20} = 0;
    end
    
    
    % All_correct_Remember_self & living
    if strcmp(Comp_data{i,2},'Remember') && Comp_data{i,3} == 1 && Comp_data{i,5} == 1 && Comp_data{i,7} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,21} = 1;
            Result_data{i+1,22} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,21} = 0;
            Result_data{i+1,22} = 1;
        else
            Result_data{i+1,21} = 0;
            Result_data{i+1,22} = 0;
        end
    else
        Result_data{i+1,21} = 0;
        Result_data{i+1,22} = 0;
    end
    
    % All_correct_Familiar_self & living
    if strcmp(Comp_data{i,2},'Familiar') && Comp_data{i,3} == 1 && Comp_data{i,5} == 1 && Comp_data{i,7} == 1
        if strcmp(MRI_data{pl,3},'SELF')
            Result_data{i+1,23} = 1;
            Result_data{i+1,24} = 0;
        elseif strcmp(MRI_data{pl,3},'ANIMACY')
            Result_data{i+1,23} = 0;
            Result_data{i+1,24} = 1;
        else
            Result_data{i+1,23} = 0;
            Result_data{i+1,24} = 0;
        end
    else
        Result_data{i+1,23} = 0;
        Result_data{i+1,24} = 0;
    end
    
end


% Remove unanswered stimuli (where the participant failed to answer the
% questions in time while inside the MRI)
for i = 1:length(sfail) % self questions not answered in time
pl = find(strcmp(Result_data, sfail{i,1}));

if isempty(pl) ~= 1
    for qz = 2:23
    Result_data{pl,qz} = 0;
    end
end
end

for i = 1:length(afail) %living questions not answered in time
pl = find(strcmp(Result_data, afail{i,1}));

if isempty(pl) ~= 1
    for qz = 2:23
    Result_data{pl,qz} = 0;
    end
end
end

% Display results for user by summing columns of the Comp_data
clear qz;
disp(strcat('Hit = ',num2str(sum([Result_data{2:end,2}])+sum([Result_data{2:end,3}]))));
disp(strcat('Hit_self = ',num2str(sum([Result_data{2:end,2}]))));
disp(strcat('Hit_living = ',num2str(sum([Result_data{2:end,3}]))));
disp(strcat('False_Alarm = ',num2str(sum([Result_data{2:end,4}])+sum([Result_data{2:end,5}]))));
disp(strcat('False_Alarm_Remember = ',num2str(sum([Result_data{2:end,4}]))));
disp(strcat('False_Alarm_Familiar = ',num2str(sum([Result_data{2:end,5}]))));
disp(strcat('Correct_Rejection = ',num2str(sum([Result_data{2:end,6}]))));
disp(strcat('Miss = ',num2str(sum([Result_data{2:end,7}])+sum([Result_data{2:end,8}]))));
disp(strcat('Miss_self = ',num2str(sum([Result_data{2:end,7}]))));
disp(strcat('Miss_living = ',num2str(sum([Result_data{2:end,8}]))));
disp(strcat('Number_Remember = ',num2str(sum([Result_data{2:end,9}])+sum([Result_data{2:end,10}]))));
disp(strcat('Number_Remember_self = ',num2str(sum([Result_data{2:end,9}]))));
disp(strcat('Number_Remember_living = ',num2str(sum([Result_data{2:end,10}]))));
disp(strcat('Number_Familiar = ',num2str(sum([Result_data{2:end,11}])+sum([Result_data{2:end,12}]))));
disp(strcat('Number_Familiar_self = ',num2str(sum([Result_data{2:end,11}]))));
disp(strcat('Number_Familiar_living = ',num2str(sum([Result_data{2:end,12}]))));
disp(strcat('Correct_Background_Remember = ',num2str(sum([Result_data{2:end,13}])+sum([Result_data{2:end,14}]))));
disp(strcat('Correct_Background_Remember_self = ',num2str(sum([Result_data{2:end,13}]))));
disp(strcat('Correct_Background_Remember_living = ',num2str(sum([Result_data{2:end,14}]))));
disp(strcat('Correct_Background_Familiar = ',num2str(sum([Result_data{2:end,15}])+sum([Result_data{2:end,16}]))));
disp(strcat('Correct_Background_Familiar_self = ',num2str(sum([Result_data{2:end,15}]))));
disp(strcat('Correct_Background_Familiar_living = ',num2str(sum([Result_data{2:end,16}]))));
disp(strcat('Correct_Question_Remember = ',num2str(sum([Result_data{2:end,17}])+sum([Result_data{2:end,18}]))));
disp(strcat('Correct_Question_Remember_self = ',num2str(sum([Result_data{2:end,17}]))));
disp(strcat('Correct_Question_Remember_living = ',num2str(sum([Result_data{2:end,18}]))));
disp(strcat('Correct_Question_Familiar = ',num2str(sum([Result_data{2:end,19}])+sum([Result_data{2:end,20}]))));
disp(strcat('Correct_Question_Familiar_self = ',num2str(sum([Result_data{2:end,19}]))));
disp(strcat('Correct_Question_Familiar_living = ',num2str(sum([Result_data{2:end,20}]))));
disp(strcat('All_Correct_Remember_self = ',num2str(sum([Result_data{2:end,21}]))));
disp(strcat('All_Correct_Remember_living = ',num2str(sum([Result_data{2:end,22}]))));
disp(strcat('All_Correct_Familiar_self = ',num2str(sum([Result_data{2:end,23}]))));
disp(strcat('All_Correct_Familiar_living = ',num2str(sum([Result_data{2:end,24}]))));

%% N-back analysis
if nbck == 1
n_back = {};

% Read in information from txt files
for z = 1:length(n_back_list)    
fid1 = fopen(n_back_list{z});

% Eliminate header information
for i = 1:6
line = fgetl(fid1);
end

% Read in information
i = 1;
while line ~= ""
    N(i,:) = textscan(line, '%d %s %s %d %d %d %d %d %d %s %s %d', 'Delimiter', '\t');
    line = fgetl(fid1);
    i=i+1;
end
n_back = [n_back;N(:,2:4)];
clear N;
end

cut = [];
% Cut Pulse data from n_back
for i = 1:length(n_back)
    if strcmp(n_back{i,1}{1},'Pulse')==1
        cut = [cut,i];
    end
end
n_back(cut,:) = [];
cut = [];
for i = 1:length(n_back)
    if strcmp(n_back{i,1}{1},'Response') == 1
        n_back{i-1,4} = 1;
        cut = [cut,i];
    end
end
n_back(cut,:) = [];


% Analyze data to see how participant did
q0 = 0;
q1 = 0;
q2 = 0;
n_back_results = {'0-back','1-back','2-back'};
for i = 1:length(n_back)
    if strcmp(n_back{i,2}{1},'0-back')
        q0 = 1;
        q1 = 0;
        q2 = 0;
    elseif strcmp(n_back{i,2}{1},'1-back')
        q0 = 0;
        q1 = 1;
        q2 = 0;
    elseif strcmp(n_back{i,2}{1},'2-back')
        q0 = 0;
        q1 = 0;
        q2 = 1;
    end
    
    if q0 == 1 && strcmp(n_back{i,2}{1},'soccerball') && isempty(n_back{i,4}) == 0  % 0-back, did the participant press a button when the soccerball was shown
        n_back_results{end+1,1} = 1;
    elseif q0 == 1 && strcmp(n_back{i,2}{1},'soccerball') && isempty(n_back{i,4})
        n_back_results{end+1,1} = 0;
    end
    
    if q1 == 1 && strcmp(n_back{i,2}{1},n_back{i-1,2}{1}) && isempty(n_back{i,4}) == 0 % 1-back, did the participant press a button when the same image was shown back-to-back
        n_back_results{end+1,2} = 1;
    elseif q1 == 1 && strcmp(n_back{i,2}{1},n_back{i-1,2}{1}) && isempty(n_back{i,4})
        n_back_results{end+1,2} = 0;
    end
       
    if q2 == 1 && strcmp(n_back{i,2}{1},n_back{i-2,2}{1}) && isempty(n_back{i,4}) == 0 % 2-back, did the participant press a button when the image shown was the same as 2 images ago
        n_back_results{end+1,3} = 1;
    elseif q2 == 1 && strcmp(n_back{i,2}{1},n_back{i-2,2}{1}) && isempty(n_back{i,4})
        n_back_results{end+1,3} = 0;
    end
    
end

end
%% SPM info
% Organizes data for input into SPM for further analysis in conjunction
% with fMRI data

cut = [];
for i = 1:length(Encode_raw)            % Cut out all data aside from when the pictures were shown
    if strcmp(Encode_raw{i,1}, 'Response')
        cut = [cut,i];
    end
end
 
Encode_raw(cut,:) = [];
Encode_raw{1,3} = 0;
 
cut = [];
pulse = Encode_raw{1,5};

% go through and remove fixations as determine when the pictures appeared
% in relation to the MRI scans

count = 0;
for i = 1:length(Encode_raw)
    if strcmp(Encode_raw{i,1},'Picture') && strcmp(Encode_raw{i,2},'fixation') == 0
        if Encode_raw{i,5} < count
            pulse = Encode_raw{i,5};
            count = Encode_raw{i,5};
        else
            count = Encode_raw{i,5};
        end
        Encode_raw{i,3} = Encode_raw{i,5} - pulse;
        
    elseif strcmp(Encode_raw{i,1},'Picture') && strcmp(Encode_raw{i,2}, 'fixation')
        if Encode_raw{i,5} < count
            pulse = Encode_raw{i,5};
            count = Encode_raw{i,5};
        else
            count = Encode_raw{i,5};
        end
        Encode_raw{i,3} =  Encode_raw{i,5} - pulse;
        cut = [cut,i];
        
    end
    if strcmp(Encode_raw{i,1},'Pulse')
        cut = [cut,i];
    end
end

Encode_raw(cut,:) = [];
Encode_raw(:,1) = [];

% Check under which condition each of the time values belongs (if the
% picture was shown at 10 seconds and fit the requirements of "Correct Remember Self" shown
% above, mark column 9 with a "1" on the row containing 10s

for i = 1:length(Encode_raw)
    Encode_raw{i,2} = round(double(Encode_raw{i,2}),-4)/10000;
    pl = find(strcmp(Result_data, Encode_raw{i,1}));
    if length(pl) > 1
        pl = pl(1);
    end
    
    % Rem_self
    if Result_data{pl,9} == 1
        Encode_raw{i,3} = 1;
    else
        Encode_raw{i,3} = 0;
    end
    
    %Rem_animacy
    if Result_data{pl,10} == 1
        Encode_raw{i,4} = 1;
    else
        Encode_raw{i,4} = 0;
    end
        
    
    %Miss_self
    if Result_data{pl,7} == 1
        Encode_raw{i,5} = 1;
    else
        Encode_raw{i,5} = 0;
    end
    
    %Miss_animacy
    if Result_data{pl,8} == 1
        Encode_raw{i,6} = 1;
    else
        Encode_raw{i,6} = 0;
    end
        
    %Familiar_self
    if Result_data{pl,11} == 1
        Encode_raw{i,7} = 1;
    else
        Encode_raw{i,7} = 0;
    end
    
    %Familiar_living
    if Result_data{pl,12} == 1
        Encode_raw{i,8} = 1;
    else
        Encode_raw{i,8} = 0;
    end
    
end

% Account for pictures where the participant failed to respond in time
% self_fail
for zzz=1:length(sfail)
for i = 1:length(Encode_raw)
    pl = strcmp(Encode_raw{i,1}, sfail{zzz,1});
    if pl
    Encode_raw{i,9} = 1;
    Encode_raw{i,3} = 0;
    Encode_raw{i,4} = 0;
    Encode_raw{i,5} = 0;
    Encode_raw{i,6} = 0;
    Encode_raw{i,7} = 0;
    Encode_raw{i,8} = 0;
    end
end
end

% living_fail
for zzzz=1:length(afail)
for i = 1:length(Encode_raw)
    pl = strcmp(Encode_raw{i,1}, afail{zzzz,1});
    if pl
    Encode_raw{i,10} = 1;
    Encode_raw{i,3} = 0;
    Encode_raw{i,4} = 0;
    Encode_raw{i,5} = 0;
    Encode_raw{i,6} = 0;
    Encode_raw{i,7} = 0;
    Encode_raw{i,8} = 0;
    Encode_raw{i,9} = 0;
    end
end
end

R_self = {};
R_animacy = {};
Miss_self = {};
Miss_animacy = {};
Familiar_self = {};
Familiar_living = {};
Failure = {};
store = -1;

% Transfer data to text file
for i=1:length(Encode_raw)
    
    if  Encode_raw{i,2} < store
        R_self{1,end+1} = 88888;
        R_animacy{1,end+1} = 88888;
        Miss_self{1,end+1} = 88888;
        Miss_animacy{1,end+1} = 88888;
        Familiar_self{1,end+1} = 88888;
        Familiar_living{1,end+1} = 88888;
        Failure{1,end+1} = 88888;
    end
    
    if Encode_raw{i,3}==1
        R_self{1,end+1} = Encode_raw{i,2};
    elseif Encode_raw{i,4}==1
        R_animacy{1,end+1} = Encode_raw{i,2};
    elseif Encode_raw{i,5}==1
        Miss_self{1,end+1} = Encode_raw{i,2};
    elseif Encode_raw{i,6}==1
        Miss_animacy{1,end+1} = Encode_raw{i,2};
    elseif Encode_raw{i,7}==1
        Familiar_self{1,end+1} = Encode_raw{i,2};
    elseif Encode_raw{i,8}==1
        Familiar_living{1,end+1} = Encode_raw{i,2};
    elseif Encode_raw{i,9} == 1 || Encode_raw{i,10} == 1
        Failure{1,end+1} = Encode_raw{i,2};
    end
    
    store = Encode_raw{i,2};
end

clear count i pl pl1 pulse q z zzz zzzz q0 q1 q2;