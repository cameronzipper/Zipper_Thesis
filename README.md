# MATLAB Analysis Scripts

Scripts for microfluidic flow and imaging analysis.  The image scripts  need the Image Processing Toolbox. Paths and parameters are set at the top of each script.

## WMVtoTIFF_Code.m
Converts time-lapse WMV videos to TIF frames, sampled every `dt` seconds by timestamp (container fps is unreliable).
**Output:** `<video>_tiffs/` folder of frames

## FITCWavefrontTracking_Code.m
FITC front speed across the channel. Draw an ROI for each dataset; arrival time is found per row and bin, and velocity comes from the median arrival time at each end.
**Output:** `velocity_profiles.csv`, `Tmap_<dataset>.png`

## COMSOLconcentrationCSV_Code.m
Same arrival-time method applied to COMSOL concentration exports, with one column per (HH, ECM_perm) condition.
**Output:** processed CSV

## COMSOLcsvProcessing_Code.m
Mean velocity vs x from a COMSOL CSV export, averaged over a set y band.
**Output:** `2dtop.xlsx`

## PIVLAB_Postprocessing_Code.m
Post-processes a PIVlab ensemble export. Averages Vx, Vy and |V| over y for each x. Run right after exporting to the workspace.
**Output:** new sheet per run in the Excel file

## HydrostaticDecay_Code.m
Checks flow steadiness from measured reservoir head decay (tau, flow rate, shear, Re).
**Output:** printed values and plots

## HUVECPixelCounter_Code.m
Segments the spheroid (FITC) and HUVECs (TRITC) using a manual threshold slider.
**Output:** `master_results.xlsx` with pixel counts
