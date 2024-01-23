function pathname = iqScratchDir()
%
% returns a directory path where scratch files can be placed
%
global scratchDir;  % remember the path, so that consecutive call run faster
% first, check if we already have a location
if (exist('scratchDir', 'var') && ~isempty(scratchDir))
    pathname = scratchDir;
else
    % first choice: \users\<username>\AppData\Local\Keysight\iqtools
    try
        userprofile = getenv('userprofile');
        if (isempty(userprofile))
            user = getenv('username');
            userprofile = fullfile('C:\Users', user);
        end
        tmpDir = fullfile(userprofile, 'AppData', 'Local', 'Keysight');
        if (exist(tmpDir, 'dir') == 0)
            mkdir(tmpDir);
        end
        tmpDir = fullfile(tmpDir, 'iqtools');
        if (exist(tmpDir, 'dir') == 0)
            mkdir(tmpDir);
        end
        pathname = tmpDir;
    catch
        % second choice: current directory
        pathname = pwd();
    end
end
% save in global variable
scratchDir = pathname;
