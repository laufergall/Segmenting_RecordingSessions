

function f_apply_sv56(executables,filename,pathFrom,pathTo)
%
% apply_sv56(filename,pathFrom,pathTo)
%
% Function to apply sv56: This is to level-equalised 26 dB below the
% overload of the digital system (-26 dBov) complying with
% ITU-T Recommendation P.56
%
% Input:
%   excutables: path to folder
%   filename: name of the file to degrade. It must be a .wav file and have
%   sufficient audio bandwidth.
%   pathFrom: path from which to read the file to degrade.
%   pathTo: path in which to write the file to degrade.
%
% Output:
%   .wav file with sv56 applied in the pathTo folder.
%
% Laura Fernández Gallardo, PhD
% <laura.fernandezgallardo@tu-berlin.de>
% http://www.qu.tu-berlin.de/?id=lfernandez
% November 2016


% Check input parameters
if nargin < 3
    disp('Wrong number of input parameters!');
else
    
    
    for f = 1:length(filename) % for each file in filename
        
        
        % Read speech to get the sampling frequency
        [speech_read,fs_read]=audioread([pathFrom,'\',filename{f}]);
        
        infilename=filename{f};
        outfilename=[filename{f}(1:end-4),'_sv56.wav'];
        
        copyfile([pathFrom,'\',filename{f}],[executables,'\',filename{f}]);
        cd(executables)
        
        
        % apply sv56 according to the fs_read
        
        if fs_read == 8000
            system(['applying_sv56_8k.bat ',infilename,' ',outfilename]);
        elseif fs_read == 16000
            system(['applying_sv56_16k.bat ',infilename,' ',outfilename]);
        elseif fs_read == 32000
            system(['applying_sv56_32k.bat ',infilename,' ',outfilename]);
        elseif fs_read == 44100
            system(['applying_sv56_44_1k.bat ',infilename,' ',outfilename]);
        elseif fs_read == 48000
            
            % It seems that sv56 does not support fs = 48 kHz
            % Resample to 44100 and apply sv56
            fs=44100;
            infilename=[filename{f}(1:end-4),'_44_1k.wav'];
            
            %  outfilename=[filename{f}(1:end-4),'_44_1k_sv56.wav'];
            outfilename=[filename{f}];
            
            
            speech_d=resample(speech_read,fs,fs_read);
            audiowrite([executables,'\',infilename],speech_d,fs);
            
            system(['applying_sv56_44_1k.bat ',infilename,' ',outfilename]);
            
        else
            error('No recognized sampling frequency')
        end
        
        movefile(outfilename,[pathTo,'\',outfilename]);
        
        % clear tmp files
        delete([executables,'/*.pcm']);
        delete([executables,'/*.wav']);
        
    end % end for each file in filename
    
end




