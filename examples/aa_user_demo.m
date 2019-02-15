% Automatic analysis (aa) - user master script example
% 
% This example runs one session of one subject through a standard SPM-based
% fMRI analysis. After running, look at the results using SPM in
% aa_demo_results/auditory/aamod_firstlevel_contrasts_00001/2014_03_29_9001/stats
%
% For this script to run, in addition to aa you will need:
%        * SPM (https://www.fil.ion.ucl.ac.uk/spm/)
%        * FSL (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
%        * wget, which is included on most Linux distributions but which
%        you will need to install on a mac (only for automatic download)
%
% v3: Johan Carlin, MRC CBU, 2018-08-06
% v2: Tibor Auer MRC Cognition and Brain Sciences Unit, 2016-02-17
% v1: Rhodri Cusack Brain and Mind Institute, Western University, 2014-12-15

%% INITIALISE
clear
aa_ver5;

%% LOAD TASKLIST
% Everything needed to run an analysis is stored in the aap structure. The
% function aarecipe initializes this structure based on a list of tasks
% (taklist, in XML format). Optionally you can also pass a set of default
% parameters: aap = aarecipe(parameters, tasklist) which set options such
% as your local data directory (where the demo dataset will be downloaded).
%
% The parametersets are XML documents, and examples can be found seen in
% the aa_parametersets folder. Typically a parameter file will start with a
% set of defaults by using an include line:
%
% <xi:include href="aap_parameters_defaults.xml" parse="xml"/>
%
% and then move on to define site- or user-specific defaults. Several of
% the defaults relate to required paths on your installation, which aa
% cannot know without your help. So before running your first analysis you
% will need to edit an XML paramter file to specify appropirate paths, or
% update the aap structure in thi script (as demonstrated in the next
% section). For the demo script we specify the default paramters and make
% any changes below, but most users of aa develop customized parametersets.
%
% For things to function appropriately, you will need a minimal
% parameterset file. You can call this anything but we will call it
% aap_parametersets_user.xml. You will use this to at the very least least
% update the directories for SPM and FSL by adding (and editing to match
% your system) lines such as the following:
%
%      
%      <spmdir desc="Path(s) to SPM (>SPM12 r6470 required)" ui="dir">/Users/peelle/software/spm12</spmdir>  
%      <fsldir desc='Path to fsl' ui='dir'>/usr/local/fsl</fsldir>
      

aap = aarecipe('aap_parameters_user.xml', 'aap_tasklist_demo.xml');



%% Make sure FSL can be used from Matlab
% (this code could also be added to startup.m, which would save you from
% adding it to individual user scripts)
 
FSLbinaryDirectory = '/usr/local/fsl/bin'; 
currentPath = getenv('PATH');
if isempty(strfind(currentPath,FSLbinaryDirectory))
    correctedPath = [ currentPath ':' FSLbinaryDirectory ];
    setenv('PATH', correctedPath);
end




%% DEFINE STUDY SPECIFIC PARAMETERS
% Having been initialized, the aap structure has a number of subfields that
% contain options about the study. Although we originally set these using
% XML parameterset (passed to aarecipe above), we can change those fields
% in a user script. Below we specify some study-specific parameters.

% aap.directory_conventions.rawdatadir is where the example data will be
% downloaded (and should exist before you run this script). Note this
% folder must be called 'aa_demo' for the data to automatically download.
%
% In this case, you can see that there is a 'data' folder, with an aa_demo
% subfolder to store various aa_demo datasets. One of these (downloaded
% below) is called aa_demo. But you can put multiple datasets in the
% aa_demo folder. 
%
% The folder you specify in aap.directory_conventions.rawdatadir should
% exist before you run this script.
aap.directory_conventions.rawdatadir = '/Users/peelle/aa/data/aa_demo';

% How to process: 'localsingle' is running on your local machine
aap.options.wheretoprocess = 'localsingle';

% Options for specific stages (here, 3 mm voxels for writing images)
aap.tasksettings.aamod_norm_write.vox = [3 3 3];
aap.tasksettings.aamod_norm_write_meanepi.vox = [3 3 3];

%% DOWNLOAD DATA
% Download the demo dataset (can comment this out if already done). The
% aa_downloaddemo function uses wget, which may not be installed on your
% computer. For Macs, you can use homebrew package manager (http://brew.sh)
% to install wget (once homebrew is installed: brew install wget).


% You will also need to make sure wget is in your path. You can use the
% GETENV function to add any location (such as /usr/local/bin) to your
% path
PATH = getenv('PATH');
setenv('PATH', [PATH ':/usr/local/bin']);

% Once wget is installed and in your path, you can download the data:
aap = aa_downloaddemo(aap);


%% SET UP DATA
% Define how subject identifier (e.g. 2014_03_29_9001) is turned into
% subject foldername in rawdatadir
aap.directory_conventions.subjectoutputformat = '%s';

aap.directory_conventions.dicomfilter='*.IMA';
aap.directory_conventions.fslshell = 'bash';

% This is name of the structural protocol, as typed into the scanner. If 
% you're consistent with this, it can be found automatically in each new subject
aap.directory_conventions.protocol_structural = 'MPRAGE  iPAT2_sag';

% Number of dummy scans at start of EPI runs
aap.acq_details.numdummies = 10;

%% STUDY INFORMATION
% Where to put the analyzed data
aap.acq_details.root = fullfile('/Users/peelle/aa/aa_demo_analysis');
aap.directory_conventions.analysisid = 'auditory';     

% Any settings for specific tasks? (These can also be set in the tasklist
% file - i.e., for this script, in aap_tasklist_demo.xml.)
aap.tasksettings.aamod_segment8.samp = 3;



% Add data:
% Add one session, lullaby_task
aap = aas_addsession(aap,'lullaby_task');

% Add one subject, S1
aap = aas_addsubject(aap,'S1','2014_03_29_9001','functional',{6});

% Add model:
% Just one regressor here ('Sound'): block onsets 0, 26, 52... 390 secs and duration 15 secs 
aap = aas_addevent(aap,'aamod_firstlevel_model','*','*','Sound',0:26:390, 15);  

% Specify contrast - sound minus silence
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts', '*', 'sameforallsessions', 1, 'sound-silence', 'T');

%% DO PROCESSING
aa_doprocessing(aap);
aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));
