
function allwritten = f_glueingDialogs(mictype, file, hastalkback, path_chunked, path_exported, path_databasefinal)
%
% allwritten = f_glueingDialogs(mictype, file, hastalkback, path_chunked, path_exported, path_databasefinal)
%
% Prepare the final database files for a given session
% and write them in wav format to the given path following a determined folder structure:
% root / mictype / session / [different dialogs]
% Sequentially, for each session to "glue":
% - Load chunk information and original recorded wavfile of the corresponding mictype
% - Create database structure for this session (speaker)
% - Glue & audiowrite the 4 scripted dialogs
% - Glue & audiowrite the semi-spontaneous dialogs, speaker turns only
% - Audiowrite other speech in sessions where the interlocutor's speech was not recorded
% - Audiowrite full semi-spontaneous dialogs when interlocutor speech is present + creating timestamps
% - Audiowrite interactions when snippet tagged as "s" or "q" or "e", and
% not within the semi-spontaneous dialogs + creating timestamps
%    
% Input:
%   mictype: 'standmic', 'tablemic', or 'headsetmic'
%   file: matfile from the chunked folder with the segmening + tags info
%	hastalkback: if = 1: this speaker has the talkback track (interlocutor's speech)
%   path_exported: where the original wavfiles of the recording session are stored
%   path_databasefinal: pointing to the root folder of the final database
%   structure
%
% Output:
%   allwritten: if = 1, it indicates that all files have been writen for
%   this session.
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% November 2016




%% parameters / variables

% keep track of speech length: 
% [scripted turns, semi-spontaneous turns, interactions, sustained, concatenations]
amountspeech=zeros(5,1);

% silence seconds at start and end of each utterance, input param for write_speech_interactions()
seconds_se=0.5;

% tmp file where to write possible problems encountered
fileproblems = fopen([path_databasefinal,'/','fileproblems.txt'],'a');




%% Load mat file, with all completed tags

load([path_chunked,'/',file.name],'audio'); 

% session ID, name for the database folder
spkfolder = strcat(audio.gender{1},num2str(audio.speakerID,'%03d'),'_',audio.pseudonym);
% disp(['...Glueing: ',spkfolder,' ',mictype])

% tmp, see all tags
% clc
% [num2cell(1:audio.nsnippets);audio.tags]'

%% Load wavfile of the corresponding mictype
if strcmp(mictype,'standmic')
    
    % Loading standmic wavfile from: ',spkfolder,' 
    [speech,fs] = audioread([path_exported,'/',audio.pseudonym,'_standmic.wav']);
    
elseif strcmp(mictype,'tablemic')
  
    % Loading tablemic wavfile from: ',spkfolder,' 
    [speech,fs] = audioread([path_exported,'/',audio.pseudonym,'_tablemic.wav']);
    
elseif strcmp(mictype,'headsetmic')
    
    % Loading headsetmic wavfile from: ',spkfolder,' 
    [speech,fs] = audioread([path_exported,'/',audio.pseudonym,'_headset.wav']);
    
else
    error('bad input parameter mictype')
end

% Load session's talkback mic (interlocutor's speech)
if hastalkback
    [speech_talkback,fs] = audioread([path_exported,'/',audio.pseudonym,'_talkback.wav']);
    % length(speech_talkback) == length(speech) - the two tracks should
    % have exactly the same number of speech samples, and same fs
end



%% Create database structure for speaker spkfolder

mkdir([path_databasefinal,'/',mictype,'/',spkfolder]);
mkdir([path_databasefinal,'/',mictype,'/',spkfolder,'/','scripted_turns']);
mkdir([path_databasefinal,'/',mictype,'/',spkfolder,'/','semispontaneous_turns']);

if hastalkback
    mkdir([path_databasefinal,'/',mictype,'/',spkfolder,'/','interactions'])
end



%% Glue & audiowrite the 4 scripted dialogs

for d = 1:4
    
    % find chunks corresponding to dialog d
    ifoundtagsd = strfind(audio.tags, num2str(d));
    itagsd = find(not(cellfun('isempty',  ifoundtagsd))); % indexes tags dialog d

    % path for database
    pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/scripted_turns'];
    
    % write wavfile with the turns found
    for t=1:length(itagsd)
        
        wavfn=[spkfolder,'_d',num2str(d),'_',audio.tags{ itagsd(t) },'_',sprintf('%02d',t),'.wav'];
        nframes = f_write_speech(audio.wavpos(itagsd(t)),speech,fs,pathTo,wavfn, fileproblems);
        
        % update counter amountspeech
        amountspeech(1) = amountspeech(1) + nframes/audio.Fs;
        
    end
    
end % end writting the 4 scripted dialogs




%% Glue & audiowrite the semi-spontaneous dialogs, speaker turns only

for d = 5:8
    
    ifoundtagsd = strfind(audio.tags, num2str(d));
    itagsd = find(not(cellfun('isempty',  ifoundtagsd))); % indexes tags dialog d
    
    if ~isempty(itagsd)
        
        % path for database
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/semispontaneous_turns'];
        
        % All turns labelled as belonging to dialog d
        wavfn=[spkfolder,'_d',num2str(d),'.wav'];
        nframes = f_write_speech(audio.wavpos(itagsd),speech,fs,pathTo,wavfn, fileproblems );
        
        % update counter amountspeech
        amountspeech(2) = amountspeech(2) + nframes/audio.Fs;
        
    end
end % end writting the 4 semi-spontaneous dialogs







%% Identify tags labelled as other speech

% all snippets tagged as "aaa" (sustained vowel a)
ifoundtagsg = cellfun(@(s) contains('aaa', s), audio.tags); % 1 or 0
itagsaaa = find(ifoundtagsg==1); % all tags labeled as good

% all snippets tagged as "d" (repeated semi-spontaneous dialog turn)
ifoundtagsg = cellfun(@(s) contains('d', s), audio.tags); % 1 or 0
itagsdiag = find(ifoundtagsg==1); % all tags labeled as d

% all snippets tagged as "s" (neutral spontaneous)
ifoundtagsg = cellfun(@(s) contains('s', s), audio.tags); % 1 or 0
itagsspeech = find(ifoundtagsg==1); % all tags labeled as speech

% all snippets tagged as "q" (spontaneous question)
ifoundtagsg = cellfun(@(s) contains('q', s), audio.tags); % 1 or 0
itagsquest = find(ifoundtagsg==1); % all tags labeled as question

% all snippets tagged as "e" (emotional spontaneous) 
ifoundtagsg = cellfun(@(s) contains('e', s), audio.tags); % 1 or 0
itagsemo = find(ifoundtagsg==1); % all tags labeled as emotional

% all snippets tagged as "f" (spontaneous short feedback)
ifoundtagsg = cellfun(@(s) contains('f', s), audio.tags); % 1 or 0
itagsf = find(ifoundtagsg==1); % all tags labeled as good

% grow amountspeech (other)
for zz=1:length(itagsf)
    frames = diff(audio.wavpos{itagsf(zz)});
    amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "f" snippets
end
for zz=1:length(itagsaaa)
    frames = diff(audio.wavpos{itagsaaa(zz)});
    amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "aaa" snippets
end
for zz=1:length(itagsspeech)
    frames = diff(audio.wavpos{itagsspeech(zz)});
    amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "s" snippets
end
for zz=1:length(itagsquest)
    frames = diff(audio.wavpos{itagsquest(zz)});
    amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "q" snippets
end
for zz=1:length(itagsemo)
    frames = diff(audio.wavpos{itagsemo(zz)});
    amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "e" snippets
end
for zz=1:length(itagsdiag)
    frames = diff(audio.wavpos{itagsdiag(zz)});
    amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "d" snippets
end







%% Write sustained "aaa" speech 

if ~isempty(itagsaaa) % only for speakers who produced the long sustained vowel
    
    mkdir([path_databasefinal,'/',mictype,'/',spkfolder,'/','sustained']);
    pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/sustained'];
    wavfn=[spkfolder,'_sustained.wav'];
    nframes = f_write_speech(audio.wavpos(itagsaaa),speech,fs,pathTo,wavfn, fileproblems );
    amountspeech(4) = amountspeech(4) + nframes/audio.Fs;
    
end



%% Audiowrite other speech in sessions where the interlocutor's speech was not recorded

% audiowrite concatenations instead of interactions:
%   - "s" snippets (_s wavfile)
%   - "q" snippets (_q wavfile)
%   - "e" snippets (_e wavfile)
if hastalkback==0 ||  (audio.speakerID >= 23 && audio.speakerID <= 30)
    
    mkdir([path_databasefinal,'/',mictype,'/',spkfolder,'/','concatenations']);
    
    if ~isempty(itagsspeech)
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/concatenations'];
        wavfn=[spkfolder,'_s.wav'];
        nframes = f_write_speech(audio.wavpos(itagsspeech),speech,fs,pathTo,wavfn, fileproblems );
        amountspeech(5) = amountspeech(5) + nframes/audio.Fs;
        
    end
    
    if ~isempty(itagsquest)
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/concatenations'];
        wavfn=[spkfolder,'_q.wav'];
        nframes = f_write_speech(audio.wavpos(itagsquest),speech,fs,pathTo,wavfn, fileproblems );
        amountspeech(5) = amountspeech(5) + nframes/audio.Fs;
        
    end
    
    if ~isempty(itagsemo)
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/concatenations'];
        wavfn=[spkfolder,'_e.wav'];
        nframes = f_write_speech(audio.wavpos(itagsemo),speech,fs,pathTo,wavfn, fileproblems );
        amountspeech(5) = amountspeech(5) + nframes/audio.Fs;
    end
    
    if ~isempty(itagsdiag)
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/concatenations'];
        wavfn=[spkfolder,'_d.wav'];
        nframes = f_write_speech(audio.wavpos(itagsdiag),speech,fs,pathTo,wavfn, fileproblems );
        amountspeech(5) = amountspeech(5) + nframes/audio.Fs;
    end
    
end




%% Audiowrite full semi-spontaneous dialogs when interlocutor speech is present + creating timestamps

if hastalkback == 1
 
    ifoundtagsd = strfind(audio.tags, '5');
    itagsd = find(not(cellfun('isempty',  ifoundtagsd))); % indexes tags dialog d5
    itagsd5=itagsd;
    ifoundtagsd = strfind(audio.tags, '8');
    itagsd = find(not(cellfun('isempty',  ifoundtagsd))); % indexes tags dialog d8
    itagsd8=itagsd;
    
    % workaround for speaker avarua (no dialog8)
    if strcmp(audio.pseudonym,'avarua')
        itagsd8(1)=audio.nsnippets - 1;
    end
    
    % Main check: where dialog tags start and end
    if itagsd5(1)-1>=1 && itagsd8(end)+1 <= audio.nsnippets

        % workaround for speaker avarua (no dialog8)
        if strcmp(audio.pseudonym,'avarua')
            itagsd8(1)=[];
        end
        
        if isempty(itagsd8) % speaker avarua
            fulldialogs=itagsd5(1)-1:itagsd5(end)+1; % from 1 before first tag d5 until last tag d5 +1
        else
            fulldialogs=itagsd5(1)-1:itagsd8(end)+1; % from 1 before first tag d5 until last tag d8 +1
            % (in case the speaker needs to start d5 again (s s s before 5), the this is saved in other interactions)
        end
        
        allwavpos=cell2mat(audio.wavpos(fulldialogs));
        wavposa=allwavpos(2:end-1); % wavpos of the interlocutor's speech

        % Tags to silence because tagged as 't' (trash)
        ifoundtagsd = strfind(audio.tags, 't');
        itagsd = find(not(cellfun('isempty',  ifoundtagsd)));
        ttags = intersect(itagsd,fulldialogs(3:end-1)); % trash tags - should be silenced
        wavposbsil = cell2mat(audio.wavpos(ttags));
        
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
        wavfn=[spkfolder,'_semispontaneousdialogs'];
        
        % write wavs (speaker and interlocutor)
        nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback,speech,fs,pathTo,wavfn);
        amountspeech(3) = amountspeech(3) + nframes/audio.Fs;

        % Create timestamp - fulldialogs
        fileID = fopen([pathTo,'/',wavfn,'_speaker_timestamps.csv'],'w');
        fprintf(fileID,'%s/n', '#,tag,timestart_s,timeend_s');
        fmt = '%d,%s,%.3f,%.3f/n';
        inittime = audio.wavpos{fulldialogs(1)}(2);
        index=1;
        for tt=1:length(fulldialogs)-2
            frames = audio.wavpos{fulldialogs(tt+1)} - inittime ;
            times_s = frames/audio.Fs + seconds_se;
            if ~strcmp(audio.tags{fulldialogs(tt+1)},'t')
                fprintf(fileID, fmt, index, audio.tags{fulldialogs(tt+1)},times_s(1), times_s(2));
                index=index+1;
            end
        end % end content of timestamps
        fclose(fileID);

    elseif itagsd8(end)+1 > audio.nsnippets

        fulldialogs=itagsd5(1)-1:itagsd8(end);

        allwavpos=cell2mat(audio.wavpos(fulldialogs));
        wavposa=[allwavpos(2:end), length(speech)];
        
        % Tags to silence because tagged as 't'
        ifoundtagsd = strfind(audio.tags, 't');
        itagsd = find(not(cellfun('isempty',  ifoundtagsd)));
        ttags = intersect(itagsd,fulldialogs(3:end)); % trash tags - should be silenced
        wavposbsil = cell2mat(audio.wavpos(ttags));
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
        wavfn=[spkfolder,'_semispontaneousdialogs'];
        
        % write wavs (speaker and interlocutor)
        nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback,speech,fs,pathTo,wavfn);
        amountspeech(3) = amountspeech(3) + nframes/audio.Fs;

        % Create timestamp - fulldialogs
        fileID = fopen([pathTo,'/',wavfn,'_speaker_timestamps.csv'],'w');
        fprintf(fileID,'%s/n', '#,tag,timestart_s,timeend_s');
        fmt = '%d,%s,%.3f,%.3f/n';
        inittime = audio.wavpos{fulldialogs(1)}(2);
        index=1;
        for tt=1:length(fulldialogs)-1
            frames = audio.wavpos{fulldialogs(tt+1)} - inittime ;
            times_s = frames/audio.Fs + seconds_se;
            if ~strcmp(audio.tags{fulldialogs(tt+1)},'t')
                fprintf(fileID, fmt, index, audio.tags{fulldialogs(tt+1)}, times_s(1), times_s(2));
                index=index+1;
            end
        end % end content of timestamps
        fclose(fileID);
        
        
    end % end checking where tags of spontaneous dialogs start and end
    
    
    

    
    %% Audiowrite interactions when snippet tagged as "s" or "q" or "e", and not within the semi-spontaneous dialogs + creating timestamps
   
    % only if no incomplete/problematic talkback (speaker abuja) and
    % speakers 23 - 30
    if ~strcmp(audio.pseudonym,'abuja') && audio.speakerID > 30

        % All snippets tagged as "t"
        ifoundtagsg = cellfun(@(s) contains('t', s), audio.tags); % 1 or 0
        itagst = find(ifoundtagsg==1); % all tags labeled as question
        
        % All snippets tagged as "f"
        ifoundtagsg = cellfun(@(s) contains('f', s), audio.tags); % 1 or 0
        itagsf = find(ifoundtagsg==1); % all tags labeled as emotional
        
        
        % looking for interaction: see if "e", "q", "s" and "f" tags are
        % consecutive
        
        sortedtags=sort([itagsspeech, itagsquest, itagsemo, itagsf]); % ,  itagst])

        a=diff(sortedtags);
        b=find([a inf]>1);
        c=diff([0 b]); % length of the sequences
        d=cumsum(c); % endpoints of the sequences
        e=d-c+1; % initpoints of the sequences
        interactions=[sortedtags(e);sortedtags(d)];
        
        % remove iteraction if found in semi-spontaneous dialog (variable fulldialogs)
        % interactions(:,interactions(1,:)>fulldialogs(1))=[];
        interactions(:, interactions(1,:) >= fulldialogs(1) & interactions(2,:) <= fulldialogs(end) )=[];
        
        % add talkback before, between-turns and after interactions
        
        for inumber=1:size(interactions,2)

            % Main check: where interaction start and end. Talkback for interaction inumber
            if interactions(1,inumber)-1>=1 && interactions(2,inumber)+1<=audio.nsnippets
                
                alltags=interactions(1,inumber)-1:interactions(2,inumber)+1;
                allwavpos=cell2mat(audio.wavpos(alltags));
                
                wavposa=allwavpos(2:end-1); %wavpos of the interlocutor's speech

                ttags = intersect(itagst,alltags(2:end-1));
                wavposbsil = cell2mat(audio.wavpos(ttags));
                
                pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
                wavfn=[spkfolder,'_interaction_',sprintf('%02d',inumber)];
                
                nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback, speech,fs, pathTo,wavfn );
                amountspeech(3) = amountspeech(3) + nframes/audio.Fs;
                
                %% Create timestamp - interaction
                fileID = fopen([pathTo,'/',wavfn,'_speaker_timestamps.csv'],'w');
                fprintf(fileID,'%s/n', '#,tag,timestart_s,timeend_s');
                fmt = '%d,%s,%.3f,%.3f/n';
                inittime = audio.wavpos{alltags(1)}(2);
                index=1;
                for tt=1:length(alltags)-2
                    frames = audio.wavpos{alltags(tt+1)} - inittime ;
                    times_s = frames/audio.Fs + seconds_se;
                    if ~strcmp(audio.tags{alltags(tt+1)},'t')
                        fprintf(fileID, fmt, index, audio.tags{alltags(tt+1)}, times_s(1), times_s(2));
                        index=index+1;
                    end
                end % end content of timestamps
                fclose(fileID);
                
                
                
            elseif interactions(1,inumber)-1<1
                
                alltags= interactions(1,inumber) : interactions(2,inumber)+1; % interactions(1,inumber)= 1
                allwavpos=cell2mat(audio.wavpos(alltags));
                
                
                wavposa=[1, allwavpos(1:end-1)]; %wavpos of the recording assistant

                ttags = intersect(itagst,alltags(1:end-1));
                wavposbsil = cell2mat(audio.wavpos(ttags));
                
                pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
                wavfn=[spkfolder,'_interaction_',sprintf('%02d',inumber)];
                
                nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback, speech,fs, pathTo,wavfn );
                amountspeech(3) = amountspeech(3) + nframes/audio.Fs;
                
                %% Create timestamp - interaction
                fileID = fopen([pathTo,'/',wavfn,'_speaker_timestamps.csv'],'w');
                fprintf(fileID,'%s/n', '#,tag,timestart_s,timeend_s');
                fmt = '%d,%s,%.3f,%.3f/n';
                inittime = 1; % audio.wavpos{alltags(1)}(2);
                index=1;
                for tt=1:length(alltags)-1
                    frames = audio.wavpos{alltags(tt)} - inittime ;
                    times_s = frames/audio.Fs + seconds_se;
                    if ~strcmp(audio.tags{alltags(tt)},'t')
                        fprintf(fileID, fmt, index, audio.tags{alltags(tt)}, times_s(1), times_s(2));
                        index=index+1;
                    end
                end % end content of timestamps
                fclose(fileID);

            elseif interactions(2,inumber)+1 > audio.nsnippets
  
                alltags= interactions(1,inumber)-1 : interactions(2,inumber);
                allwavpos=cell2mat(audio.wavpos(alltags));

                wavposa=[allwavpos(2:end), length(speech)]; 
                
                % Tags to silence because tagged as 't'
                ttags = intersect(itagsd,alltags(2:end)); % trash tags - should be silenced
                wavposbsil = cell2mat(audio.wavpos(ttags));
                
                pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
                wavfn=[spkfolder,'_interaction_',sprintf('%02d',inumber)];
                
                nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback, speech,fs, pathTo,wavfn );
                amountspeech(3) = amountspeech(3) + nframes/audio.Fs;
                
                %% Create timestamp - interaction
                fileID = fopen([pathTo,'/',wavfn,'_speaker_timestamps.csv'],'w');
                fprintf(fileID,'%s/n', '#,tag,timestart_s,timeend_s');
                fmt = '%d,%s,%.3f,%.3f/n';
                inittime = audio.wavpos{alltags(1)}(2);
                index=1;
                for tt=1:length(alltags)-1
                    frames = audio.wavpos{alltags(tt+1)} - inittime ;
                    times_s = frames/audio.Fs + seconds_se;
                    if ~strcmp(audio.tags{alltags(tt+1)},'t')
                        fprintf(fileID, fmt, index, audio.tags{alltags(tt+1)}, times_s(1), times_s(2));
                        index=index+1;
                    end
                end % end content of timestamps
                fclose(fileID);
                
                
            end % end ckecing where interaction start and end.
            
        end  % end for each interaction

    end % checking spk is not "abuja" && spk ID > 30
      
end  % checking hastalkback



%% Finishing 

% write file with amount of speech (one row per speaker)
fileID = fopen([path_databasefinal,'/amountspeech.csv'],'a');
fmt = '%s,%s,%s,%s,%s,%s/n';
fprintf(fileID, fmt, spkfolder, num2str(amountspeech(1)), num2str(amountspeech(2)), num2str(amountspeech(3)), num2str(amountspeech(4)), num2str(amountspeech(5)));
fclose(fileID);


% Close file where to write problem encountered
fclose(fileproblems);

% return value
allwritten=1;
