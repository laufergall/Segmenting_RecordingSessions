

function isalltagged = f_tagging(file, tagscommands, path_chunked, path_exported_sv56)
%
% isalltagged = f_tagging(file, tagscommands, path_chunked, path_exported_sv56)
%
% A loop is implemented in this function to listen through all chunks of a given
% recording session and provide an appropriate tag to each of them.
% Tags need to be chosen from tagscommands
% No need to listen to the complete chunk before inserting a tag.
%
% Input:
%   file: mat file corresponding to a recording session with information
%   about the chunks.
%   tagscommands: tags to choose from. Keywords like 'quit', 'save',
%   'mcut',.., read from tagscommands.csv
%   path_chunked: path where 'file' is stored
%   path_exported_sv56: path where the level-normalized .wav files are
%   stored
%
% Output:
%   The given tags are saved as a field of the struct in the input mat file
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% November 2016



%% Parameters
isalltagged=0; % flag to be 1 when speaker completed. Returned value


%% Load audio structure with chunk information
load([path_chunked,'/',file.name]);
spkinfo=[audio.pseudonym,'	ID=',num2str(audio.speakerID)];


%% Load the corresponfding speech file
[speech_read, Fs_read] = audioread([path_exported_sv56,'/',audio.wavfilename]);
speech=resample(speech_read,audio.Fs,Fs_read); % audio.Fs = 48000,  Fs_read = 44100


%% Init j (goes through all snippets in the while loop)

% find the first non-tagged snippet
istagged = cellfun(@(s) ~isempty(s), audio.tags);
nontagged=find(istagged==0);
first_nontagged=nontagged(1);
j=first_nontagged;
fprintf('\n');
disp(['**** Start tagging: ',spkinfo,' ****'])
fprintf('\n');
if first_nontagged~=1
    disp('**** Starting by non-tagged snippets ****')
end
% otherwise, start all over: j=1;

%% Loop to tag the whole file

while j<=length(audio.audio)
    
    % prepaer audioplayer to play the audio in this chunk
    p=audioplayer(audio.audio{j},audio.Fs);
    
    % feedback for the annotator
    secondsinfo=[num2str(length(audio.audio{j})/audio.Fs),' s'] ;
    snippetinfo=['Snippet: ',num2str(j),' of ',num2str(audio.nsnippets)];
    info = ['[',spkinfo,']     ',snippetinfo,'     ',secondsinfo];
    disp(info)
    
    try
        play(p);
    catch
        % workaround in case the audio cannot be played
        audiowrite([path_exported_sv56,'\tagme.wav'],audio.audio{j},audio.Fs);
        disp('please listen to tagme.wav in path_exported_sv56')
    end
    
    in=input('Enter Tag: ','s');
    
    % look for the entered tag on the list of tagscommands.csv
    foundentered=cellfun(@(s) strcmp(s,in), tagscommands(:,1));
    
    
    %% Perform an action based on the inserted tag
    
    if sum(foundentered)==1
        
        % display to the annotator what key/tag/command was entered + description
        fprintf('"%s" -> %s -> %s\n\n',tagscommands{foundentered,:});
        
        
        
        % save changes, without quitting
        if strcmp(in,'save')
            
            disp('Saving changes, please wait...')
            save(file.name,'audio');
            disp('Saved')
            
            % quit (save at the end of the loop)
        elseif strcmp(in,'quit')
            break
            
            % this session needs to be segmented again with a different threshold
        elseif strcmp(in,'cutagainbetter')
            
            isalltagged=-1;
            break  % quit (save at the end of the loop)
            
            % modify this chunk adding speech information from the
            % back (until the beginning of the next chunk)
        elseif strcmp(in, 'cback')
            
            % snippet + segment at the end until next snippet
            audio.audio{j}=speech(audio.wavpos{j}(1):audio.wavpos{j+1}(1));
            audio.wavpos{j}=[audio.wavpos{j}(1),audio.wavpos{j+1}(1)];
            
            % modify this chunk adding speech information from the
            % front (until the end of the previous chunk)
        elseif strcmp(in, 'cfront') % cutthisfront
            
            %  segment from end of previous snippet + snippet
            audio.audio{j}=speech(audio.wavpos{j-1}(2):audio.wavpos{j}(2));
            audio.wavpos{j}=[audio.wavpos{j-1}(2),audio.wavpos{j}(2)];
            
            % modify this chunk adding speech information from the
            % front and from the back
        elseif strcmp(in, 'cutthismore')
            
            % snippet + segments at both sides
            audio.audio{j}=speech(audio.wavpos{j-1}(2):audio.wavpos{j+1}(1));
            audio.wavpos{j}=[audio.wavpos{j-1}(2),audio.wavpos{j+1}(1)];
            
            % go to the previous chunk (to modify tag)
        elseif strcmp(in,'back')
            j=max(j-1,1);
            
            % play this chunk again
        elseif strcmp(in,'play')
            play(p);
            
            % insert a comment
        elseif strcmp(in,'comment')
            newcomment=input('Your new comment: ','s');
            audio.comments=sprintf('%s\n%s',audio.comments,newcomment);
            disp(['All comments on ', spkinfo])
            disp(audio.comments);
            
            % display information about tags commands
        elseif strcmp(in,'info')
            
            for i=1:size(tagscommands,1)
                fprintf('"%s" -> %s -> %s\n',tagscommands{i,:});
            end
            
            % Glue two chunks, since they belong to the same speaker turn
            % (the silence between these two chunks was too long or should not have been detected)
        elseif strcmp(in,'glue')
            
            snippet1s=input('Enter number of the first chunk: ','s');
            snippet2s=input('Enter number of the second chunk: ','s');
            
            snippet1=str2num(snippet1s);
            snippet2=str2num(snippet2s);
            
            if snippet2-snippet1==1 && snippet1>=1 && snippet2<=audio.nsnippets
                
                au=speech(audio.wavpos{snippet1}(1):audio.wavpos{snippet2}(2)); % snippet1 + segment in the middle + snippet2
                audio.audio=[audio.audio(1:snippet1-1), au, audio.audio(snippet2+1:audio.nsnippets)];
                
                wp=[audio.wavpos{snippet1}(1), audio.wavpos{snippet2}(2)];
                audio.wavpos=[audio.wavpos(1:snippet1-1), wp, audio.wavpos(snippet2+1:audio.nsnippets)];
                
                audio.tags=[audio.tags(1:snippet1-1), audio.tags(snippet1), audio.tags(snippet2+1:audio.nsnippets)];
                audio.tagsnatural=[audio.tagsnatural(1:snippet1-1), audio.tagsnatural(snippet1), audio.tagsnatural(snippet2+1:audio.nsnippets)];
                
                audio.nsnippets = audio.nsnippets-1;
                
                % tag the new glued audio in the next loop iteration
                j=snippet1;
                
            else
                disp('Not glued. Chunks have to be consecutive')
            end
            
            % Manually select cut point from the speech plot
        elseif strcmp(in,'mcut')
            
            h=figure;
            plot(audio.audio{j})
            try
                p = ginput(1);
                close(h);
                cutpoint=round(p(1));
                
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
                
                % tag from the new cut audio in the next loop iteration
                
            catch
                disp('Figure closed. Do mcut again?')
            end
            
            
        else
            
            % Add tag to chunk and go to next audio chunk
            audio.tags{j}=in;
            j=j+1;
            
        end
        
    else
        disp('Not recognized input. Please enter input again')
    end
end




%% Check if speaker tagging is finished
istagged = cellfun(@(s) ~isempty(s), audio.tags);
if isempty(find(istagged==0, 1)) % all tags exist
    isalltagged=1; % return value
    disp(['All tagging completed for: ',spkinfo])
else
    disp(['Still to be tagged: ',num2str(length(audio.tags)-find(istagged==0, 1)),' snippets from ',spkinfo])
end


%% Save changes
disp('Saving changes, please wait...')
save(file.name,'audio');
disp('Saved')
disp(['**** End tagging [',spkinfo,'] ****'])

