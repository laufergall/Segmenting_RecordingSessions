
# Segmenting and Tagging Speech Recording Sessions

## Overview

We conducted 300 speech recording sessions in 2016/2017 at the [Quality and Usability Lab](http://www.qu.tu-berlin.de/menue/qu/) of the Technische Universität Berlin for the collection of the [Nautilus Speaker Characterization (NSC) Corpus](http://www.qu.tu-berlin.de/?id=nsc-corpus). Long, continuous wavfiles of approx. 40 minutes were aquired from each of the microphones employed. We then used this tool to sort out the speech that corresponded to each dialog. In other words, we assigned utterances to the different parts of the database design.

This repository contains Matlab scripts for:
* **segmenting speech recording sessions** - partition speech into sentences, based on detected silences.
* **tagging speaker turns** -  assign a tag to each of the speech segments, e.g. dialog 1a, emotional speech, questions,...

For details on the purpose of employing these scripts, see Section 2 of the [NSC Documentation](http://www.qu.tu-berlin.de/fileadmin/fg41/users/fernandez.laura/NSC_documentation_v01.pdf).

**No audio** or means to recover the speech recording sessions are provided in this repository. Speakers' names are pseudo anonymized.

## Steps

From main.m, all the following steps are run for each speech recording session:

#### 0. Preparation

* sets paths - paths pointing to folders with .wav, .mat, .m, files or to final compiled database.

* load 'segmenting.mat' - to keep track of what steps have been done or need to be done for each speaker's session. 

	* We need to take into account that each speech recording session corresponds to a different speaker, and there were 300 speakers in total. There are three different microphones used in each recording session.
	* Before/after each step, the file 'segmenting.mat' is checked/updated.

* load 'tagscommands.csv' - commands used by the annotator to indicate the given tag in the "Tagging" step.

#### 1. Normalizing level

* The speech from the whole recording session (from folder **'all_exported'**) is level-equalized to -26dB, using the voltmeter algorithm of ITU-T Rec. P.56. This is done by the **'f_apply_sv56()'** function.
* Resulting level-equalized .wav files are stored in the **'all_exported_sv56'** folder.

#### 2. Segmenting / Chunking

* Call the function **'f_chunk_speech()'** to create chunks and store the information of the cut segments into a .mat file, needed for the next steps. 
   * The segmenting is based on enveloping the speech and low-pass filtering to detect silent regions that determine the cut points. 
   * It might be necessary to manually adjust the threshold to detect sounds.
   * This function is based on a script written by Lars-Erik Riechert.
* Resulting mat files are stored in the **'chunked'** folder.

#### 3. Tagging

* Call the function **'f_tagging()'** with the chunked recording session (a .mat file in the **'chunked'** folder). 
* The task for the annotator is to  listen to a chunk and insert a tag (from 'tagscommands.csv'). No need to listen to the complete chunk before inserting a tag. The tags are saved as a field of the struct in the mat file.
* The procedure repeats going through all session chunks - unless the annotator inserts 'quit'.
* Afterwards,  **'f_tagging()'** is called again with next session to tag - this is repeated until no files are left or the annotator inserts 'no'. 

#### 4. Glueing

The database wav files are created based on chunks and tags, and written following the database folder structure.
* For each of the three microphones used in a session, call **'f_glueingDialogs()'** :
	* determine which tags correspond to the same speech element (e.g. scriped dialog, semi-spontaneous dialog, interaction,..).
	* call **'f_write_speech()'** and **'f_write_speech_interactions()'** to write the speech  with the found tags in the database structure.
* This process is repeated for all sessions. As a result, the speech database is organized and ready to be shared!


## Folder structure

#### all_exported

Original .wav files from the mono-speaker recording sessions. In the case of NSC data, these were exported from Cubase 4, the software used to record the speech. 

There is a speech file for each microphone and speaker. Some speakers were recorded with only one microphone - this is taken into account in segmenting.mat.

The files are named with the speaker's pseudonym and microphone. Examples: 'aden_headset.wav', 'debrecen_standmic', 'santodomingo_tablemic.wav', 'tallinn_talkback'.

#### all_exported_sv56

Level-equalized .wav files, originated after the "1. Normalizing level" step.

#### chunked

Chunked speech, stored in .mat files, each of them with a struct with the fields: audio (audio samples in each snippet), wavpos (for each snippet), tags (for each snippet), Fs, wavfilename, pseudonym, speakerID, gender, nsnippets, comments.

#### executables

Files necesary to level-equalize the speech in step "1: Normalizing level".

#### input

Contains 'segmenting.mat' and 'tagscommands.csv' needed for step "0: Preparation", and 'IDs_pseudonyms.mat' with the mappings of speake IDs, gender, and pseudonym. These files were used in the case of the NSC database. For a new application, new appropriate files need to be created.

#### matlab

Matlab scripts that perform the steps mentioned above.

#### NSC_root
Final database files generated (.wav), after the "Glueing" step, are stored here. The files are allocated in the 'headsetmic', 'standmic', or 'tablemic' folders depending on the microphone with which the speech was acquired.


## TODO
This tool can be improved for other speech databases:
* Since our recorded sessions had a very silent background, the current method to detect silences worked satisfactorily. However, it could be substituted by a more sophisticated one, especially if the recording background is more noisy. Ideally, the threshold would be automatically adapted to each recorded file. I like for instance the [semi-supervised speech activity detector](http://cs.joensuu.fi/pages/tkinnu/webpage/) implementation by Dr. Tomi H. Kinnunen.
* We could include a check to perform the steps sequentially.
* Include scripts to refine dialogs by selecting the most natural realizations (not done for NSC corpus). The less natural realizations can be left out from the final database.