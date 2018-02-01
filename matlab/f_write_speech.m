
% Write speech with fadein/fadeout for every segment


function nframes = f_write_speech(wavpos, speech, fs, pathTo, filename, fileproblems )

% wavpos=audio.wavpos(itagsd(t)); wavpos=audio.wavpos(itagsd);  speech=speech_standmic; fs = 48000;
% pathTo='D:\Users\fernandez.laura\Downloads'; filename='holahola.wav';
% test wavpos
% [speech, fs1]=audioread('D:\Users\fernandez.laura\Documents\Work\WP1_Data_collection\Segmenting\Exported_test_sv56\hamhung_standmic_44_1k_sv56.wav');
% [speech_standmic, fs]=audioread('D:\Users\fernandez.laura\Documents\Work\WP1_Data_collection\Segmenting\Exported_test_sv56\hamhung_standmic_44_1k_sv56.wav');
% sound(final_speech,fs1)
% sound(final_speech_faded, fs1)

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


nframes = length(final_speech);


