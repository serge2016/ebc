Last modification date: 22.11.2018 08:00

1. MSM -> DAT using Mascot on a Windows-based machine. To process MSM-files:
1.1. Start Mascot Daemon Application. Go to 'Parameter Editor' tab. Click 'Open', select 'Mascot_Daemon_Kristina04_NCBInr.par' file and check all parameters. Change anything if necessary, and, if so, save the file with another name.
1.2. Go to 'Task Editor' tab. Parameter set: ... -> select the file from the previous step. Task: enter the task name without any spaces.
1.3. Start Total Commander. Go to the folder, where all MSM files are located (possibly in subfolders). Search for all *.msm files in this folder (Alt+F7). Press 'Files to the panel' button. Select all files (Ctrl+A) [288 files in this case]. If it is necessary, deselect any of the files. Using the mouse drag selected files to the white field 'Data file list' in the Mascot Daemon. Comment! Such a procedure is necessary to save the correct alphabetical order of the samples from different datasets. As a second option it is possible to add the datasets in the correct order to one task. Otherwise tasks will run in parallel and it would be mess in the output files.
1.4. Check the empty space on the local disk C: [7 MB for 1 DAT-file, so approximately 2,5-3 GB].
1.5. Press 'Run'. It should take about 24 hours.
1.6. After the run is finished in the 'c:\PF2\Mascot\data\' folder should apper one or several folders with current date (the date of this run), and the DAT-files are supposed to be in this folder(-s). These DAT-files (F00????.dat) should be converted to HTM-reports (see next).

2. DAT -> HTM using Mascot script on a Windows-based machine:
2.1. DAT-files from previous step (subfolder(-s) with dates in the 'c:\PF2\Mascot\data\' folder) are inputs for this step.
2.2. Important! Change the lines in the 'Kristina_datToHtm_v05_1.cmd' script:
	set inputDir=c:/PF2/Mascot/data/20181104
	set outputDirProts=c:\PF2\Mascot\Kristina\Mia2018\Mia2018_4htmProts
	set outputDirPepts=c:\PF2\Mascot\Kristina\Mia2018\Mia2018_4htmPepts
2.3. Run script 'Kristina_datToHtm_v05_1.cmd' to convert mascot DAT-files to HTM-files with proteins and HTM-files with peptides simultaneously. Script will also rename the HTM-files according to MSM-files (their names are stored into DAT-files).
2.4. To fix the links and to work in the web-browsers correctly HTM-files should be modified: add the following line into the <HEAD> tag:
	<base href="http://filimonovpc/mascot/cgi/">
The current version of the 'Kristina_datToHtm_v05_1.cmd' script already does it.

3. Run 'mascot_extract_2peptides_from_htm_v11.sh' script to generate a summary TSV-file with peptides and their frequencies in different samples.
