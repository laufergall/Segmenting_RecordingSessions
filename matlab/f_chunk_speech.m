

function f_chunk_speech(file, path_input, pathTo)
%
% f_chunk_speech(file, path_input, pathTo)
%
% A "long" speech file corresponding to long recording session (mono speaker)
% is chunked into utterances (to be tagged in a subsequent step).
%
% Input:
%   file: wavfile to chunk
%   pathInput: ../input path, with the IDs_pseudonyms.mat file
%   pathTo: path where the resulting .mat files will be stored
%
% Output: a .mat file is generated, with a struct with the fields: 
%   audio (audio samples in each snippet), 
%   wavpos (for each snippet), 
%   tags (for each snippet), 
%   Fs,
%   wavfilename, 
%   pseudonym, 
%   speakerID,
%   gender, 
%   nsnippets, 
%   comments
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% Based on a script from Lars-Erik Riechert <lars-erik.riechert@campus.tu-berlin.de>
% November 2016


%% Parameters
gapsize=1;								% seconds. how long should it be silent to detect a gap and cut the audio 
threshold=0.02; 						% default: 0.02. define threshold for silence detection
ssfact=5;								% subsampling factor to fasten processing
extratime=0.5;							% number of seconds that still belong to the record after quiteness has been detected
prevtime=0.3;							% number of seconds that still belong to the record before signal has been detected
minlength=0.2 + extratime + prevtime;	% signals shorter than minlength s will be deleted in the end
Fs=48000;

%% Create audio structure
audio=struct('audio',[]);



%% Read speech file (sv56) and resample to 48 kHz
[y_read, Fs_read] = audioread(file.name);
y=resample(y_read,Fs,Fs_read);


%% Look for silences to compute ending positions
%if length(y)<Fs*2									% (optional) skip files shorter than 2s

envelope = abs(y);							% envelope before subsampling, to maintain consonants at beginning and end of words
envelope=(downsample(envelope,ssfact));

windowSize = Fs/5/ssfact;
envelopelp=filter(ones(1,windowSize)/windowSize,1,envelope); % low-pass filter

a=find(envelopelp>threshold);				% positions with active speech
a=a-windowSize/2-1;							% correct for filter delay
a(a<1)=1;
a=a*ssfact;									% rescale on original sampling rate
b=find(diff(a)>Fs*gapsize);					% ending positions by looking for gaps longer than gapsize
audio.audio={};
audio.wavpos={};

if isempty(b)
    audio.audio{1}=y;
    %wavwrite(y,Fs,['seg\',files(i).name])
    %continue
else
    for j = 0:length(b)						%cutting audio in single sentences
        if j==length(b)
            audio.audio{j+1}=y(a(b(j)+1)-Fs*prevtime: min(a(end)+Fs*extratime,length(y)));
            audio.wavpos{j+1}=[a(b(j)+1)-Fs*prevtime,min(a(end)+Fs*extratime,length(y))];		%orginal position in wave file, allows to cut the other channels simoultaniously
        elseif j==0
            audio.audio{j+1}=y(max(1,a(1)-Fs*prevtime):a(b(j+1))+Fs*extratime);
            audio.wavpos{j+1}=[max(1,a(1)-Fs*prevtime),a(b(j+1))+Fs*extratime];
        else
            audio.audio{j+1}=y(a(b(j)+1)-Fs*prevtime:min(length(y),a(b(j+1))+Fs*extratime));
            audio.wavpos{j+1}=[a(b(j)+1)-Fs*prevtime,min(length(y),a(b(j+1))+Fs*extratime)];
        end
    end
end


%% Remove segments shorter than minlength
for j = 1:length(b)						
    if  length(audio.audio{j}) < Fs*minlength
        audio.audio{j}=[];
        audio.wavpos{j}=[];
    end
end
audio.audio=audio.audio(~cellfun('isempty',audio.audio));
audio.wavpos=audio.wavpos(~cellfun('isempty',audio.wavpos));



%% Look for speaker ID and gender
ff=strfind(file.name,'_');
city= file.name(1:ff(1)-1);
% load cell array with the mapping: [id, pseudonym, gender]
load([path_input,'\IDs_pseudonyms.mat'],'IDs_pseudonyms') 
found=cellfun(@(s) strcmp(s,city), IDs_pseudonyms(:,2));
spkid=IDs_pseudonyms{found,1};
spkgender=IDs_pseudonyms{found,3};



%% More in audio structure and save in pathTo
audio.tags=cell(1,length(audio.audio));
audio.Fs=Fs;        % sv56 files are resampled to 48000 to match the Fs of the exported files.
audio.wavfilename=file.name;
audio.pseudonym = city; % Speaker Pseudonym
audio.speakerID = spkid;   
audio.gender = spkgender;
audio.nsnippets = length(audio.audio);
audio.comments='';

save([pathTo,'\', audio.pseudonym,'.mat'],'audio');

