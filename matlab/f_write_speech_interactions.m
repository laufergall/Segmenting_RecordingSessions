
% Write speech with fadein/fadeout for every segment


% write stereo speech for interations. 
% Channel a: recording assistant. Channel b: speaker. 
% Called from f_glueingDialogs
% No fading
%   wavposa: wavpos for all turns for recording assistant
%   wavposb: wavpos for all turns for speaker
%   speechtb: speech talk back (recording assistant)
%   speaker's speech, from one of the microphones
%   fs: sampling frequency of the speech.
%   pathTo: path where to write the resulting stereo file
%   filename: filename of the stereo file



function nframes = f_write_speech_interactions(wavposa, wavposbsil, speechtb, speech, fs, pathTo, filename)

% speech=speech_standmic; speechtb=speech_talkback; fs = 48000;
% pathTo='D:\Users\fernandez.laura\Downloads'; filename='holahola.wav';


%% Parameters
% fade_length = 0.3; % seconds fade
% fade_samples = round(fade_length.*fs); % figure out how many samples fade is over
% fade_scale = linspace(0,1,fade_samples)'; % create fade

% Silence segments
seconds_se=0.5; % start and end
sil_se=zeros(seconds_se*fs,1);

% allowing overlapping speech instead of silencing the microphones while
% the other turn. Copy the two whole chunks
segmenta = speechtb(wavposa(1):wavposa(end)); % wavposb(end-1));
segmentb = speech(wavposa(1):wavposa(end)); % wavposb(end-1));

% silence speech labelled as 't': noises, clearing up throat, speaker saying his own name... other non-speech events
for i=1:2:length(wavposbsil)

    % overwrite with zeros
    % sound(segmentb( (wavposbsil(i)- wavposa(1)):(wavposbsil(i+1)-wavposa(1))), 48000); % double-checking
    segmentb(  (wavposbsil(i)- wavposa(1)):(wavposbsil(i+1)- wavposa(1))  ) = zeros (length(wavposbsil(i):wavposbsil(i+1)),1);
    
%     if length(segmenta)-length(segmentb)~=0
%     error
%     end
end

% silence at start and at the end
final_speecha=[sil_se; segmenta; sil_se];
final_speechb=[sil_se; segmentb; sil_se];

% better to make all mono files, no stereo
% final_speech=[final_speecha, final_speechb];


%% Write final_speech in the pathTo folder
audiowrite([pathTo,'/',filename,'_interlocutor.wav'],final_speecha,fs);
audiowrite([pathTo,'/',filename,'_speaker.wav'],final_speechb,fs);


nframes = length(final_speecha);
