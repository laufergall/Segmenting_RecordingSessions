

% Main file to segment and label speech recording sessions
%	0. Preparation: paths, load data
%   1. apply sv56 to complete recording sessions to normalize sound levels
%   2. Segment speech into chunks (speaker turns) for each level-normalized file
%   3. Given the chunked speech, tagging speaker turns
%   4. Glueing dialogs & sorting tagged speech & writing wavfiles to the database structure

% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% November 2016


clear
clc


%% 0. Preparation: paths, load data

% Set paths
path_mscripts = pwd; % needs to be set to this script's directory
path_root = fileparts(path_mscripts); % this script's parent directory
path_exported = [path_root,'\all_exported'];
path_exported_sv56 = [path_root,'\all_exported_sv56'];
path_chunked = [path_root,'\chunked'];
path_input = [path_root,'\input'];

path_databasefinal = [path_root,'\NSC_root']; % at least ~150 GB free to allocate the 3 database versions
path_databasefinal_standmic=[path_databasefinal,'\standmic'];
path_databasefinal_tablemic=[path_databasefinal,'\tablemic'];
path_databasefinal_headsetmic=[path_databasefinal,'\headsetmic'];

addpath(path_mscripts)


% Load segmenting.mat struct, controlling what has been done
load([path_input,'\segmenting.mat']);

% Import tags commands and inform
tagscommands=f_importtagscommands([path_input,'/tagscommands.csv']);
for i=1:size(tagscommands,1)
    fprintf('"%s" -> %s -> %s\n',tagscommands{i,:});
end



%% 1. apply sv56 to normalize sound levels
% The created _44_1k_sv56.wav file is only used as reference for segmenting

files_wav=dir([path_exported,'\*.wav']);

% filenames to cell. easy to search string later
fn_wav=cell(length(files_wav),1);
for i=1:length(files_wav)
    fn_wav{i}=files_wav(i).name;
end

% take only the files recorded with standmic (generally, better quality)
f1 = strfind(fn_wav, '_standmic.wav');
indexes = find(not(cellfun('isempty', f1)));

cd(path_mscripts)

for i=1:length(indexes)
    
    fn=fn_wav{indexes(i)};
    ff=strfind(fn,'_');
    pseudonym= fn(1:ff(1)-1);
    
    % check whether this speaker needs to be level-normalized (sv56ed)
    if segmenting.issv56ed(found)==0
        
        % perform sv56 level-normalization.
        disp(['...Level-normalizing: ',pseudonym]);
        f_apply_sv56(executables, {fn}, path_exported, path_exported_sv56);
        
        % update segmenting.mat
        segmenting.issv56ed(found)=1;
        save([path_input,'\segmenting.mat'],'segmenting');
    end
end






%% 2. Segment speech into chunks (speaker turns) for each level-normalized file
% generated mat files are stored in ../chunked

% wav files in the path where level-normalized speech is stored (only standmic)
files_wav=dir([path_exported_sv56,'/*.wav']);

for i=1:length(files_wav)
    
    fn=files_wav(i).name;
    ff=strfind(fn,'_');
    pseudonym= fn(1:ff(1)-1);
    found=cellfun(@(s) strcmp(s,pseudonym), segmenting.pseudonym);
    
    % check whether the session has not been chunked yet
    if segmenting.issoundanalized(found)==0
        
        % chunk the recording session corresponding to this speaker (pseudonym)
        disp(['...Chunking: ',pseudonym]);
        f_chunk_speech(files_wav(i), path_input, path_chunked);
        
        % update segmenting.mat
        segmenting.issoundanalized(found)=1;
        save([path_input,'\segmenting.mat'],'segmenting');
        
    end
end






%% 3. Given the chunked speech, tagging speaker turns
% Main task for the annotator: listen to audio and insert a tag

% mat files in the path where chunked information speech is stored
files_mat=dir([path_chunked,'\*.mat']);

% run f_tagging for all mat files (speakers) until the annotator inserts "no" or "quit"
quit=0;
for i=1:length(files_mat)
    
    % check whether the session has not been tagged yet
    pseudonym=files_mat(i).name(1:end-4);
    found=cellfun(@(s) strcmp(s,pseudonym), segmenting.pseudonym);
    
    if segmenting.isalltagged(found)==0
        
        flag=0; % when flag = 1, go to next speaker
        while(flag==0)
            in=input(['Start tagging speaker "',files_mat(i).name(1:end-4),'"? (yes/quit/next) '],'s');
            if strcmp(in,'yes')
                
                % tag the chunks corresponding to this speaker
                isalltagged = f_tagging(files_mat(i), tagscommands, path_exported_sv56);
                
                if isalltagged ==1
                    % update segmenting.mat
                    segmenting.isalltagged(found)=1;
                    save([path_input,'\segmenting.mat'],'segmenting');
                    flag = 1; % break the while and next speaker
                    
                elseif strcmp(in,'quit')
                    disp('All good. Exiting.')
                    quit=1;
                    break
                elseif strcmp(in,'next')
                    flag = 1; % break the while and next speaker
                end
            end
        end
        
        if (quit==1)
            break
        end
        
        if (i==length(files_mat))
            disp('No more .mat files available to be tagged. Exiting.')
        end
    end
    
end



%% 4. Glueing dialogs & sorting tagged speech & writing wavfiles to the database structure path_databasefinal

% original speech files and chucked tagged speech
files_wav=dir([path_exported,'\*.wav']);
files_mat=dir([path_chunked,'\*.mat']);

% filename to cell. easy to search string later
fn_wav=cell(length(files_wav),1);
for i=1:length(files_wav)
    fn_wav{i}=files_wav(i).name;
end

for spk= 1:length(files_mat)
    
    pseudonym=files_mat(spk).name(1:end-4);
    found=cellfun(@(s) strcmp(s,pseudonym), segmenting.pseudonym);
    
    % check whether the session needs to be tagged
    if segmenting.isallwritten(found)==0
        
        cd(path_chunked) % come back from database structure to path_chunked
        
        % glue files recorded with standup mic
        allwritten = f_glueingDialogs_standmic(files_mat(spk), segmenting.hastalkback(found), path_exported, path_databasefinal_standmic);
        
        % glue files recorded with standup mic
        if segmenting.has3mics(found)
            f_glueingDialogs_tablemic(files_mat(spk), segmenting.hastalkback(found), path_exported, path_databasefinal_tablemic);
            f_glueingDialogs_headsetmic(files_mat(spk), segmenting.hastalkback(found), path_exported, path_databasefinal_headsetmic);
        end
        
        % update segmenting.mat
        segmenting.isallwritten(found)=allwritten;
        save([path_input,'\segmenting.mat'],'segmenting');
    end
    
end


