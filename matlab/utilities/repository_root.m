function rootDir = repository_root()
%REPOSITORY_ROOT Return the absolute path to the repository root.

thisFile = mfilename('fullpath');
rootDir = fileparts(fileparts(fileparts(thisFile)));
end
