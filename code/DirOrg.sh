
PROJECT_DIR = 

FS_DIR = 

FMRI_DIR = 


#Remove SUBJ subdir in FS
cd $FS_DIR
for dir in REMBRANDT-x-*; do
    #mv "$dir/$dir/"* "$dir/"
    rmdir "$dir/$dir"
done

#Clean Sub IDs in FS
for dir in REMBRANDT-x-*; do
  cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-([0-9]+)-.*/\1/')
  mv "$dir" "$cleandir"
done

#Clean Sub IDs in functional data
cd $FMRI_DIR

#Add task name
