# ICONIP2016

## How to run:

1. Download the tst v2 dataset available at http://www.tlc.dii.univpm.it/blog/databases4kinect and copy to the same location where you downloaded the classifier.

2. If necessary, set the function set_environment for your current path

3. Run iconip_tstv2classifier.m 

## Using another dataset

This code was also tested with the CORNELL CAD60 dataset and our falling stick model. The parameters for running the classifier are defined in the body of the function named starter_script.m on the classifier directory. The work was concentrated on falling actions, so there are some known issues with the partitioning of the CORNELL dataset; as there are many different actions, there is no guarantee that every action will be present on both sets. Also, using generating sets with only positions is no longer possible, but one may use only positions for classifications by specifying 'pos' in the allconn definition (but since this is done inside the algorithm, it hinders comparisons with other classifiers). 

