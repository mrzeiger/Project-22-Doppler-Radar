# Project-22-Doppler-Radar

This Github is composed of scripts pertaining to the 2023-2024 NCSU ECE Senior Design Project 22 

The first script is "binfile_convert.mlx" This is a MatLab live script that takes the .BIN file that is output from mmWave studio, and outputs an array of data. This array of data is composed of the returned In-Phase and Quadrature data from your collection. This data array can then be used for further processing. To use the script, you will need to change the "fileName" variable to be equal to your respective file name of the data you collected, as well as you will need to change any other parameters that are often changed in data collection to ensure they are the same as how you collected data. For example, if you increase the number of ADC samples per chirp, then you would need to change the "numADCSamples" variable. This script was obtained from a TI instructional PDF, found here: https://www.ti.com/lit/an/swra581b/swra581b.pdf?ts=1713080462729
