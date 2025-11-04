
PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt

#FS_DIR = 

FMRI_DIR=$PROJECT_DIR/Baseline-fMRI_REST1-VUMC 


#Remove SUBJ subdir in FS
#cd $FS_DIR
#for dir in REMBRANDT-x-*; do
#    #mv "$dir/$dir/"* "$dir/"
#    rmdir "$dir/$dir"
#done

#Clean Sub IDs in FS
#for dir in REMBRANDT-x-*; do
#  cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-([0-9]+)-.*/\1/')
#  mv "$dir" "$cleandir"
#done

#Clean Sub IDs in functional data
cd $FMRI_DIR
for dir in REMBRANDT-x-*; do
  cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-([0-9]+)-.*/\1/')
  echo mv "$dir" "$cleandir"

#Add task name
