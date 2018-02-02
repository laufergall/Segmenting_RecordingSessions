

function nframes = f_write_speech(wavpos, speech, fs, pathTo, filename, fileproblems)
%
% nframes = f_write_speech(wavpos, speech, fs, pathTo, filename, fileproblems)
%
% Write speech file with fadein/fadeout for every segment
%
% Input:
%   wavpos: positions (frame numbers) that limit the chunks, corresponding
%   to 'speech'
%   speech: speech samples (full session) 
%   fs: sampling frequency of 'speech'
%   pathTo: where to audiowrite the generated file
%   filename: name of the file to be written
%   fileproblems: pointer to the txt file where to log possible problems
%   encountered
%
% Output:
%   nframes: total number of frames written, needed in f_glueingDialogs()
%   to keep track of the amount of speech generated
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% November 2016


%% Parameters
fade_length = 0.3; % seconds fade
fade_samples = round(fade_length.*fs); % figure out how many samples fade is over
fade_scale = linspace(0,1,fade_samples)'; % create fade

% Silence segments
seconds_sil=0.7; % between turns
seconds_se=0.5; % start and end
sil=zeros(seconds_sil*fs,1);
sil_se=zeros(seconds_se*fs,1);


%% Go through wavpos, fade, and concatenate with silence between turns
final_speech=[];

for i=1:length(wavpos) % =1 if writing scripted turns
    
    
    if wavpos{i}(2)>wavpos{i}(1) && fade_samples < (wavpos{i}(2)-wavpos{i}(1))
        segment = speech(wavpos{i}(1):wavpos{i}(2)); % sound(segment, audio.Fs)
        
        segment_faded = segment;
        segment_faded(1:fade_samples) = segment_faded(1:fade_samples).*fade_scale; % apply fadein
        segment_faded(end-fade_samples+1:end) = segment_faded(end-fade_samples+1:end).*fade_scale(end:-1:1); % apply fadeout
        
        
        if i<length(wavpos)
            final_speech=[final_speech; segment_faded; sil];
        else
            % final segment, or length(wavpos)==1, then do not incorporate silence
            final_speech=[final_speech; segment_faded];
        end
        
    else
        fprintf(fileproblems,'%s\n', [filename,': problems with wavpos{i}(2)<wavpos{i}(1) or fade_samples < (wavpos{i}(2)-wavpos{i}(1)), i= ', num2str(i)]);
    end
    
end

% silence at start and at the end
final_speech=[sil_se; final_speech; sil_se];


%% Write final_speech in the pathTo folder
audiowrite([pathTo,'/',filename],final_speech,fs);

%% Return number of frames of the written speech
nframes = length(final_speech);


