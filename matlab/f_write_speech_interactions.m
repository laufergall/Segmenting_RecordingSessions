
function nframes = f_write_speech_interactions(wavposa, wavposbsil, speechtb, speech, fs, pathTo, filename)
%
% nframes = f_write_speech_interactions(wavposa, wavposbsil, speechtb, speech, fs, pathTo, filename)
%
% Write two speech files, corresponding to the speaker and to the
% interlocutor, respectively. No fading.
%
% Input:
%   wavpos: positions (frame numbers) that limit the chunks, corresponding
%   to the interlocutor's turns
%   wavposbsil, 
%   speechtb: speech samples from the interlocutor (full session) 
%   speech: speech samples from the speaker (full session) 
%   fs: sampling frequency of 'speech' and of 'speechtb' 
%   pathTo: where to audiowrite the generated files 
%   filename: name of the file to be written
%
% Output:
%   nframes: total number of frames written from the interlocutor's speech, 
%   needed in f_glueingDialogs() to keep track of the amount of speech generated
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% November 2016


% Silence segments
seconds_se=0.5; % start and end
sil_se=zeros(seconds_se*fs,1);

% allowing overlapping speech instead of silencing the microphones while
% the other turn. Copy the two whole chunks
segmenta = speechtb(wavposa(1):wavposa(end)); % wavposb(end-1));
segmentb = speech(wavposa(1):wavposa(end)); % wavposb(end-1));

% silence speech labelled as 't': noises, clearing up throat, speaker saying his own name... other non-speech events
for i=1:2:length(wavposbsil)

    % sound(segmentb( (wavposbsil(i)- wavposa(1)):(wavposbsil(i+1)-wavposa(1))), 48000); % double-checking
    segmentb(  (wavposbsil(i)- wavposa(1)):(wavposbsil(i+1)- wavposa(1))  ) = zeros (length(wavposbsil(i):wavposbsil(i+1)),1);

end

% silence at start and at the end
final_speecha=[sil_se; segmenta; sil_se];
final_speechb=[sil_se; segmentb; sil_se];


%% Write final_speech mono files in the pathTo folder
audiowrite([pathTo,'/',filename,'_interlocutor.wav'],final_speecha,fs);
audiowrite([pathTo,'/',filename,'_speaker.wav'],final_speechb,fs);


%% Return number of frames of the written interlocutor's speech
nframes = length(final_speecha);
