


% f_glueingDialogs_02: from all microphones (version of the database with all microphones, just for me)
% f_glueingDialogs_03: only from standmic microphone (final version of the
% database). also: writes amount of speech recorded in seconds (scripted turns, semi-spontaneous turns, other speech (s, q, e, ok, aaa) ).
%
% Save dialogs, speech, affirmations,  ...
% and talkback -> building interactions
% called from mail_lavelall as: allwritten = f_glueingDialogs_02(files_mat(i), segmenting.hastalkback(found), segmenting.has3mics(found), path_exported, path_databasefinal);
% calls f_write_speech, which adds fadein/fadeout to every segment
% creates folders of the database structure
% audiowrites the 4 scripted dialogs (*not* looking for "g" of natural tags)
% audiowrites the 4 semi-spontaneous dialogs (_mono.wav and also if talkback: as interaction
% Creates interactions with all "e" and "l" snippets
% Concatenates & audiowrites all "ok" snippets (_shortfeedbacks.wav)
% Concatenates & audiowrites all "aaa" snippets (_sustained.wav)


function allwritten = f_glueingDialogs(mictype, file, hastalkback, path_chunked, path_exported, path_databasefinal)
%
% allwritten = f_glueingDialogs(mictype, file, hastalkback, path_chunked, path_exported, path_databasefinal)
%
% prepare the final database files for a given session
% and write them in wav format to the given path following a determined folder structure:
% root / mictype / session / [different dialogs]
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
disp(['...Glueing: ',spkfolder])

% tmp, see all tags
% clc
% [num2cell(1:audio.nsnippets);audio.tags]'

% Load wavfile of the corresponding mictype
if mictype=='standmic'
    
    disp(['**** Loading standmic wavfile from: ',spkfolder,' ****'])
    [speech,fs] = audioread([path_exported,'/',audio.pseudonym,'_standmic.wav']);
    
elseif mictype=='tablemic'
  
    disp(['**** Loading tablemic wavfile from: ',spkfolder,' ****'])
    [speech,fs] = audioread([path_exported,'/',audio.pseudonym,'_tablemic.wav']);
    
elseif mictype=='headsetmic'
    
    disp(['**** Loading headsetmic wavfile from: ',spkfolder,' ****'])
    [speech,fs] = audioread([path_exported,'/',audio.pseudonym,'_headset.wav']);
    
else
    error('bad input parameter mictype')
end

% Load session's talkback mic (interlocutor's speech)
if hastalkback
    [speech_talkback,fs] = audioread([path_exported,'/',audio.pseudonym,'_talkback.wav']);
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
        nframes = f_write_speech(audio.wavpos(itagsd(t)),speech,fs,pathTo,wavfn, fileproblems );
        
        % update counter amountspeech
        amountspeech(1) = amountspeech(1) + nframes/audio.Fs;
        
    end
    
end % end writting the 4 scripted dialogs




%% Glue & audiowrite the semi-spontaneous dialogs

% disp(['**** Writting semi-spontaneous turns for: ',spkfolder,' ****'])

% If talkback, write full files (speaker + interlocutor since first tag of dialog5
% else write only speaker (all turns labelled as belonging to the same dialog) in mono file
for d = 5:8
    
    ifoundtagsd = strfind(audio.tags, num2str(d));
    itagsd = find(not(cellfun('isempty',  ifoundtagsd))); % indexes tags dialog d
    
    if ~isempty(itagsd)  % it will be empty for speaker 'avarua' d6, d7, d8
        % Path for database
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/semispontaneous_turns'];
        
        % All turns labelled as belonging to dialog d
        wavfn=[spkfolder,'_d',num2str(d),'.wav'];
        nframes = f_write_speech(audio.wavpos(itagsd),speech,fs,pathTo,wavfn, fileproblems );
        
        % update counter amountspeech
        amountspeech(2) = amountspeech(2) + nframes/audio.Fs;
        
    end
end % end for each dialog







%% Other speech, labelled as "s" or "q" or "l" or "e", "ok" snippets, "aaa"

% disp(['**** Writting other speech wavfiles for: ',spkfolder,' ****'])


% All snippets tagged as "aaa"
ifoundtagsg = cellfun(@(s) ~isempty(strfind('aaa', s)), audio.tags); % 1 or 0
itagsaaa = find(ifoundtagsg==1); % all tags labeled as good

% All snippets tagged as "d"
ifoundtagsg = cellfun(@(s) ~isempty(strfind('d', s)), audio.tags); % 1 or 0
itagsdiag = find(ifoundtagsg==1); % all tags labeled as d

% All snippets tagged as "s"
ifoundtagsg = cellfun(@(s) ~isempty(strfind('s', s)), audio.tags); % 1 or 0
itagsspeech = find(ifoundtagsg==1); % all tags labeled as speech

% All snippets tagged as "q"
ifoundtagsg = cellfun(@(s) ~isempty(strfind('q', s)), audio.tags); % 1 or 0
itagsquest = find(ifoundtagsg==1); % all tags labeled as question

% All snippets tagged as "e" (before "e" and "l")
ifoundtagsg = cellfun(@(s) ~isempty(strfind('e', s)), audio.tags); % 1 or 0
itagsemo = find(ifoundtagsg==1); % all tags labeled as emotional

% All snippets tagged as "f" (before: "ok")
ifoundtagsg = cellfun(@(s) ~isempty(strfind('f', s)), audio.tags); % 1 or 0
itagsf = find(ifoundtagsg==1); % all tags labeled as good







% %% grow amountspeech (other)
% for zz=1:length(itagsf)
%     frames = diff(audio.wavpos{itagsf(zz)});
%     amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "f" snippets
% end
% for zz=1:length(itagsaaa)
%     frames = diff(audio.wavpos{itagsaaa(zz)});
%     amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "aaa" snippets
% end
% for zz=1:length(itagsspeech)
%     frames = diff(audio.wavpos{itagsspeech(zz)});
%     amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "s" snippets
% end
% for zz=1:length(itagsquest)
%     frames = diff(audio.wavpos{itagsquest(zz)});
%     amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "q" snippets
% end
% for zz=1:length(itagsemo)
%     frames = diff(audio.wavpos{itagsemo(zz)});
%     amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "e" snippets
% end
% for zz=1:length(itagsdiag)
%     frames = diff(audio.wavpos{itagsdiag(zz)});
%     amountspeech(3) = amountspeech(3) + frames/audio.Fs; % "d" snippets
% end







%% write aaa speech in the Sustained folder

if ~isempty(itagsaaa) % some speakers (ID < 121) did not do this
    
    mkdir([path_databasefinal,'/',mictype,'/',spkfolder,'/','sustained']);
    pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/sustained'];
    wavfn=[spkfolder,'_sustained.wav'];
    nframes = f_write_speech(audio.wavpos(itagsaaa),speech,fs,pathTo,wavfn, fileproblems );
    amountspeech(4) = amountspeech(4) + nframes/audio.Fs;
end









% if no hastalkback or if speakerID in 23:30 (no interactions)
% audiowrite concatenations instead of interactions:
%   - "s" snippets (_s wavfile)
%   - "q" snippets (_q wavfile)
%   - "e" snippets (_e wavfile)
if hastalkback==0 ||  ( audio.speakerID >= 23 && audio.speakerID <= 30)
    
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





if hastalkback == 1
    
    
    
    %% Save semi-spontaneous dialogues full
    
    
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
    
    % "standard way"
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
        wavposa=allwavpos(2:end-1); % wavpos of the recording assistant
        wavposb=allwavpos(3:end); % wavpos of the speaker % not needed
        % anymore because we are not going to fade
        
        % Tags to silence because tagged as 't'
        
        ifoundtagsd = strfind(audio.tags, 't');
        itagsd = find(not(cellfun('isempty',  ifoundtagsd)));
        ttags = intersect(itagsd,fulldialogs(3:end-1)); % trash tags - should be silenced
        wavposbsil = cell2mat(audio.wavpos(ttags));
        
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
        wavfn=[spkfolder,'_semispontaneousdialogs'];
        
        %% write wavs (speaker and interlocutor)
        nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback,speech,fs,pathTo,wavfn);
        amountspeech(3) = amountspeech(3) + nframes/audio.Fs;
        
        
        %% Create timestamp - fulldialogs
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
        wavposb=[allwavpos(3:end), length(speech)];
        
        % Tags to silence because tagged as 't'
        
        ifoundtagsd = strfind(audio.tags, 't');
        itagsd = find(not(cellfun('isempty',  ifoundtagsd)));
        ttags = intersect(itagsd,fulldialogs(3:end)); % trash tags - should be silenced
        wavposbsil = cell2mat(audio.wavpos(ttags));
        
        pathTo=[path_databasefinal,'/',mictype,'/',spkfolder,'/interactions'];
        wavfn=[spkfolder,'_semispontaneousdialogs'];
        
        %% write wavs (speaker and interlocutor)
        nframes = f_write_speech_interactions(wavposa, wavposbsil, speech_talkback,speech,fs,pathTo,wavfn);
        amountspeech(3) = amountspeech(3) + nframes/audio.Fs;
        
        
        
        %% Create timestamp - fulldialogs
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
        
        
        
    end % end checking "standard way"
    
    
    
    
    
    
    
    
    
    
    
    %% Save interaction when snippet labelled as "s" or "q" or "e", and not within the semi-spontaneous dialogs
    
    % only if no incomplete/problematic talkback (speaker abuja) and
    % speakers 23 - 30
    if ~strcmp(audio.pseudonym,'abuja') && audio.speakerID > 30
        
        %         disp(['**** Writting interaction wavfiles for: ',spkfolder,' ****'])
        
        
        % All snippets tagged as "t"
        ifoundtagsg = cellfun(@(s) ~isempty(strfind('t', s)), audio.tags); % 1 or 0
        itagst = find(ifoundtagsg==1); % all tags labeled as question
        
        % All snippets tagged as "f"
        ifoundtagsg = cellfun(@(s) ~isempty(strfind('f', s)), audio.tags); % 1 or 0
        itagsf = find(ifoundtagsg==1); % all tags labeled as emotional
        
        
        % looking for interaction: see if tags concatenated
        
        %         % only e, q, s
        %         sortedtags=sort([itagsspeech, itagsquest, itagsemo]); % ,  itagst, itagsf]);
        
        % e, q, s and also f
        sortedtags=sort([itagsspeech, itagsquest, itagsemo, itagsf]); % ,  itagst, itagsf]);
        
        
        % Taking also ok and trash:
        %sortedtags=sort([itagsspeech, itagsquest, itagsemo,  itagst, itagsf]);
        
        %
        
        
        a=diff(sortedtags);
        b=find([a inf]>1);
        c=diff([0 b]); % length of the sequences
        d=cumsum(c); % endpoints of the sequences
        e=d-c+1; % initpoints of the sequences
        interactions=[sortedtags(e);sortedtags(d)];
        
        % remove iteraction if found in semi-spontaneous dialog (variable fulldialogs)
        % interactions(:,interactions(1,:)>fulldialogs(1))=[];
        interactions(:, interactions(1,:) >= fulldialogs(1) & interactions(2,:) <= fulldialogs(end) )=[];
        
        
        %     % check if same tag number and it was tagged corresponding to "t" or "f" -> then dont write. else: do write this (short interaction)
        %     singleturns = find(interactions(1,:)-interactions(2,:)==0);
        %     unimportanttags = [itagst, itagsf];
        %     index=1;
        %     for ii=1:length(singleturns)
        %          if find(  unimportanttags == interactions(1,singleturns(ii)) )
        %             % save index remove this interaction from the interactions matrix
        %           remo(index)=ii;
        %           index=index+1;
        %          end
        %     end
        %     interactions(:,singleturns(remo))=[];
        %
        
        
        % add talkback before, between-turns and after interactions
        
        for inumber=1:size(interactions,2)
            
            
            
            
            
            
            % ("standard way") talkback for interaction inumber
            if interactions(1,inumber)-1>=1 && interactions(2,inumber)+1<=audio.nsnippets
                
                alltags=interactions(1,inumber)-1:interactions(2,inumber)+1;
                allwavpos=cell2mat(audio.wavpos(alltags));
                
                wavposa=allwavpos(2:end-1); %wavpos of the recording assistant
                wavposb=allwavpos(3:end); %wavpos of the speaker
                
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
                wavposb=allwavpos(1:end); %wavpos of the speaker
                
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
                wavposb=[allwavpos(3:end), length(speech)];
                
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
                
                
                
            end % check "standard way"
            
        end  % end for each interaction
        
        
    end % checking spk is not "abuja"
    
    
end  % checking hastalkback



% write amount of speech (one row per speaker)
fileID = fopen([path_databasefinal,'/amountspeech.csv'],'a');
fmt = '%s,%s,%s,%s,%s,%s/n';
fprintf(fileID, fmt, spkfolder, num2str(amountspeech(1)), num2str(amountspeech(2)), num2str(amountspeech(3)), num2str(amountspeech(4)), num2str(amountspeech(5)));
fclose(fileID);


% Close file where to write problem encountered
fclose(fileproblems);



% return value
allwritten=1;
