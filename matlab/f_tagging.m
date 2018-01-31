

function isalltagged = f_tagging(file, tagscommands, path_exported_sv56)
%
% isalltagged = f_tagging(file, tagscommands, path_exported_sv56)
%
% A loop is implemented in this function to listen through all chunks of a given
% recording session and provide an appropriate tag (to choose from tagscommands.csv).
% No need to listen to the complete chunk before inserting a tag. 
%
% Input:
%   file: mat file corresponding to a recording session with information
%   about the chunks.
%   tagscommands: 
%   path_exported_sv56: path where the level-normalized .wav files are
%   stored
%
% Output: 
%   The given tags are saved as a field of the struct in the input mat file
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% Based on a script from Lars-Erik Riechert <lars-erik.riechert@campus.tu-berlin.de>
% November 2016



%% Parameters
isalltagged=0; % flag to be 1 when speaker completed. Returned value



%% Load audio structure
load(file.name);
spkinfo=[audio.pseudonym,'	ID=',num2str(audio.speakerID)];


%% Load the corresponfding speech file
[speech_read, Fs_read] = audioread([path_exported_sv56,'/',audio.wavfilename]);
speech=resample(speech_read,audio.Fs,Fs_read); % audio.Fs = 48000,  Fs_read = 44100


j=1;
%% tmp comment for 157 and 170
% %% Init j (goes through all snippets in the while loop)
% % find the first non-tagged snippet
% istagged = cellfun(@(s) ~isempty(s), audio.tags);
% nontagged=find(istagged==0);
% first_nontagged=nontagged(1);
% j=first_nontagged;
% fprintf('\n');
% disp(['**** Start tagging: ',spkinfo,' ****'])
% fprintf('\n');
% if first_nontagged~=1
%     disp('**** Starting by non-tagged snippets ****')
% end
% % otherwise, start all over: j=1;

%% Loop to tag the whole file

while j<=length(audio.audio)
    
    
    p=audioplayer(audio.audio{j},audio.Fs);
    
    %user feedback
    secondsinfo=[num2str(length(audio.audio{j})/audio.Fs),' s'] ;
    snippetinfo=['Snippet: ',num2str(j),' of ',num2str(audio.nsnippets)];
    info = ['[',spkinfo,']     ',snippetinfo,'     ',secondsinfo];
    disp(info)
    
    try
        play(p);
    catch
        % workaround, cut a bit the speech so that it can be played
        audiowrite('tagme.wav',audio.audio{j},audio.Fs);
        disp('please listen to tagme.wav')
    end
    
    in=input('Enter Tag: ','s');
    
    foundentered=cellfun(@(s) strcmp(s,in), tagscommands(:,1));
    
    if sum(foundentered)==1
        
        % Display to the user what key/tag/command was entered + description
        fprintf('"%s" -> %s -> %s\n\n',tagscommands{foundentered,:});
        
        %% Control commands
        if strcmp(in,'save')
            %% Save changes
            disp('Saving changes, please wait...')
            save(file.name,'audio');
            disp('Saved')
            
            
        elseif strcmp(in,'quit')	%quit (save at the end of the loop)
            break
            
        elseif strcmp(in,'cutagainbetter')
            % This speaker needs f_sound_analysis again with a different threshold
            isalltagged=-1;
            break  %quit (save at the end of the loop)
            
            % (save anyway at the end of the loop or when the user quits)
            %         elseif strcmp(in,'save')	% save changes
            %             disp('Saving changes, please wait...')
            %             save(file.name,'audio');
            %             disp('Saved')
            
        elseif strcmp(in, 'cback') % cutthisbehind
            
            % cut speech corresponding to this snippet from the sv56ed wavfile
            audio.audio{j}=speech(audio.wavpos{j}(1):audio.wavpos{j+1}(1)); % snippet + segment at the end until next snippet
            audio.wavpos{j}=[audio.wavpos{j}(1),audio.wavpos{j+1}(1)];
            
        elseif strcmp(in, 'cfront') % cutthisfront
            
            % cut speech corresponding to this snippet from the sv56ed wavfile
            audio.audio{j}=speech(audio.wavpos{j-1}(2):audio.wavpos{j}(2)); %  segment from end of previous snippet + snippet
            audio.wavpos{j}=[audio.wavpos{j-1}(2),audio.wavpos{j}(2)];
            
            
        elseif strcmp(in, 'cutthismore')
            
            % cut speech corresponding to this snippet from the sv56ed wavfile
            audio.audio{j}=speech(audio.wavpos{j-1}(2):audio.wavpos{j+1}(1)); % snippet + segments at both sides
            audio.wavpos{j}=[audio.wavpos{j-1}(2),audio.wavpos{j+1}(1)];
            
        elseif strcmp(in,'back') % go back (to modify tag)
            j=max(j-1,1);
            
        elseif strcmp(in,'play') % play again
            play(p);
            
            
            
        elseif strcmp(in,'comment') % intert a comment
            newcomment=input('Your new comment: ','s');
            audio.comments=sprintf('%s\n%s',audio.comments,newcomment);
            disp(['All comments on ', spkinfo])
            disp(audio.comments);
            
            
        elseif strcmp(in,'info')
            % Inform about tags commands
            for i=1:size(tagscommands,1)
                fprintf('"%s" -> %s -> %s\n',tagscommands{i,:});
            end
            
            
        elseif strcmp(in,'glue')  % Glue two snippets, tehre is no turn in the middle
            
            snippet1s=input('Enter number of the first snippet: ','s');
            snippet2s=input('Enter number of the second snippet: ','s');
            
            snippet1=str2num(snippet1s); % this is j
            snippet2=str2num(snippet2s); % this is j
            
            if snippet2-snippet1==1 && snippet1>=1 && snippet2<=audio.nsnippets
                
                % au=[audio.audio{snippet1}; audio.audio{snippet2}];
                au=speech(audio.wavpos{snippet1}(1):audio.wavpos{snippet2}(2)); % snippet1 + segment in the middle + snippet2
                audio.audio=[audio.audio(1:snippet1-1), au, audio.audio(snippet2+1:audio.nsnippets)];
                
                wp=[audio.wavpos{snippet1}(1), audio.wavpos{snippet2}(2)];
                audio.wavpos=[audio.wavpos(1:snippet1-1), wp, audio.wavpos(snippet2+1:audio.nsnippets)];

                audio.tags=[audio.tags(1:snippet1-1), audio.tags(snippet1), audio.tags(snippet2+1:audio.nsnippets)];
                audio.tagsnatural=[audio.tagsnatural(1:snippet1-1), audio.tagsnatural(snippet1), audio.tagsnatural(snippet2+1:audio.nsnippets)];
                
                audio.nsnippets = audio.nsnippets-1;
                
                % tag the new glued audio - in the next loop iteration
                j=snippet1;
                
            else
                disp('Not glued. Turns have to be consecutive')
            end
            
            
        elseif strcmp(in,'mcut')  % manualcut Manual cut point
            
            h=figure;
            plot(audio.audio{j})
            try
                p = ginput(1);
                close(h);
                cutpoint=round(p(1)); %  cutpoint=input('Enter cut point: ','s');
                
                % Insert new cell according to cutpoint in  audio.wavpos, audio.audio, audio.tags, position j
                
                wp1=[audio.wavpos{j}(1), audio.wavpos{j}(1)+cutpoint];
                wp2=[audio.wavpos{j}(1)+cutpoint+1, audio.wavpos{j}(2)];
                audio.wavpos=[audio.wavpos(1:j-1),wp1,wp2,audio.wavpos(j+1:audio.nsnippets)];
                
                au1=audio.audio{j}(1:cutpoint);
                au2=audio.audio{j}(cutpoint:length(audio.audio{j}));
                audio.audio=[audio.audio(1:j-1), au1, au2, audio.audio(j+1:audio.nsnippets)];
                
                
                audio.tags=[audio.tags(1:j-1), audio.tags(j), audio.tags(j), audio.tags(j+1:audio.nsnippets)];
                audio.tagsnatural=[audio.tagsnatural(1:j-1), audio.tagsnatural(j), audio.tagsnatural(j), audio.tagsnatural(j+1:audio.nsnippets)];
                
                audio.nsnippets = audio.nsnippets+1;
                
                % tag from the new cut audio - in the next loop iteration
                
            catch
                disp('Figure closed. Do mcut again?')
            end
            
        elseif strcmp(in,'g') || strcmp(in,'b')
            % do not react. These commands are for building dialogs
        else
            
            %% Add tag and next audio snippet
            audio.tags{j}=in;
            j=j+1;
            
        end
        
    else
        disp('Not recognized input. Please enter input again')
        
    end
    
    
    
end













%% Check if speaker tagging is finished
istagged = cellfun(@(s) ~isempty(s), audio.tags);
if isempty(find(istagged==0, 1)) %% all tags exist
    isalltagged=1; % return value
    disp(['All tagging completed for: ',spkinfo])
else
    disp(['Still to be tagged: ',num2str(length(audio.tags)-find(istagged==0, 1)),' snippets from ',spkinfo])
end

%% Save changes
disp('Saving changes, please wait...')
save(file.name,'audio');
disp('Saved')

%% Message end
disp(['**** End tagging [',spkinfo,'] ****'])











