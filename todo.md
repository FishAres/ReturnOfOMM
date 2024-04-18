## Re-analyzing OMM data

[ X ] Create function that returns a dict with all the activities, aux vars, behavior, animals for a given proj_meta file

[ X ] Clean up data
    * [ X ] Remove duplicate grating onsets (keep first)
    * [ X ] Function to pad n-d array to desired dims
        * [ ] Make it faster with fewer allocations
        * [ X ] Remove "flips" from the condition 3 recordings where we used 100% flip occurence to show the right grating
    * Later
        * [ ] Remove duplicate grating onsets (keep longest)
        * [ ] Add option to keep incomplete traversals

[ ] Reproduce paper figures
    * [ ] Figure 1
        * [ X ] Classification of grating + position across conditions
        * [ ]  // // across timepoints (/ hours?)
        * [ ] Plot some cell examples (maybe extract feature weights from random forest?)
    * [ ] Figure 2
        * [ X ] Spatial binning of activity
        * [ ] Show mean grating-evoked activity per condition
        * [ ] Show distribution of peaks for selective cells
        * [ ] Show (clustered?) activity in spatial coordinates
    * [ ] Figure 3
        * [ ] Quantify "grating belief" as a function of time/condition
        * [ ] Plot anticipatory vs visual cell activity before/after flips (and other grating onsets). Find a sensible way to do it for cell pairs

    * [ ] Figure 4
        * [ ] Plot population response to omission
        * [ ] Plot "omission-selective" cells


[ ] Other analyses
    * [ ] What happens with mixed-selectivity cells during flips/omissions?
    * [ ] Plot peak flip response as function of cell's peak location for A, B
    * [ ] Predict some behavioral feature from neuronal activity
        * [ ] Same for CA1, ACC
    * [ ] Think of interesting analyses to do. Prioritize insight over technical sexiness
    

[ ] Things to fix / change
    * [ ] Undo `get_act_dict`, use `proj_meta` directly for analyses
    * [ ] 

[ ] ?

[ ] Profit