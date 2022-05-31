Toolkit to analyse synapse terminals (and their interaction with MG IPL protrusions)
(1) "SynapseTerminal_SegmentationAndFeatures.ijm" 
    (a) input images are single-channel (i.e. synapse staining like Ribeye) 3D stacks
    (b) iterate over images in the folder 
    (c) identify IPL
    (d) segmentation of synapse terminals
    (e) synapse terminal quantification
    (f) write outputs
    (g) the number of synapses comes from the 3D Obj counter file
(2) "SynapseTerminal_RewriteOutputfiles.ijm" (optional)
    this macro will rewrite the outputs of "SynapseTerminal_SegmentationAndFeatures.ijm" into a more convenient format for later processing
(3) "MGData_ExtractIPLandSegmentation.ijm"
    (a) will use ROIs from "SynapseTerminal_SegmentationAndFeatures.ijm" to extract IPL in the MG channel
    (b) performs preprocessing and segmentation
    (c) will perform synapse terminal and MG density analysis
    (d) will perform synapse terminal and MG overlap analysis
    (e) the number of synapses comes from the 3D Obj counter file