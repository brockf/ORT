ORT
===

Run an Object Representation & Tracking (ORT) study in Matlab with minimal configuration. This is useful for developmental psychologists who want to examine infants' visual short term memory for objects and features.

## How to use ORT

### Download ORT

* Download ort.m and the example "commfeat" study folder
* Create a folder in your Matlab directory and place these files inside of it
* Add this folder to your list of Matlab paths

### Create a new study

* Copy the example study folder, "commfeat", into a subfolder of your main ORT directory
* Modify `config.txt` with the configuration options for the new study
* Modify the stimuli in the `stimuli` sub-folder.

### Run a session

* Load Matlab
* Type `ort` in the command prompt
* Select your new study folder and click "Open"
* Follow on-screen prompts (e.g., enter the experimenter's name, infant's subject code, age, etc.)
* Code the infant's looking using the LeftArrow (for a right look), RightArrow (for a left look), and DownArrow (for a center look)
* A log for the session will be created in the `logs` sub-folder
* A session file (with looking time results, participant details, and session metadata) will be created in the `sessions` sub-folder

## Author, Copyright, & Citation

All original code written by and copyright (2013), [Brock Ferguson](http://www.brockferguson.com). I am a researcher at Northwestern University study infant conceptual development and language acquisition.

You can cite this software using:

> Ferguson, B. (2013). Object Representation & Tracking (ORT) for Matlab. Retrieved from https://github.com/brockf/ORT.

This code is **completely dependent** on the [PsychToolbox library for Matlab](http://psychtoolbox.org/PsychtoolboxCredits). You should absolutely cite them if you use this library:

> Brainard, D. H. (1997) The Psychophysics Toolbox, Spatial Vision 10:433-436.

> Pelli, D. G. (1997) The VideoToolbox software for visual psychophysics: Transforming numbers into movies, Spatial Vision 10:437-442.

> Kleiner M, Brainard D, Pelli D, 2007, "What's new in Psychtoolbox-3?" Perception 36 ECVP Abstract Supplement.
