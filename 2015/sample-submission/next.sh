#! /bin/bash

# file: next.sh

# This bash script analyzes the record named in its command-line
# argument ($1), and writes the answer to the file 'answers.txt'.
# This script is run once for each record in the Challenge test set.
#
# The program should print the record name, followed by a comma,
# followed by a 1 (for a true alarm) or 0 (for a false alarm.)
#
# For example, if invoked as
#    next.sh 100 Asystole
# it analyzes record 100 and (assuming the alarm is considered to be
# false) writes "100,0" to answers.txt.
#
# To run in batch mode:
#
# rm -f answers.txt; for i in `cat ./challenge/set-p/RECORDS`; do rec=`echo ${i} | cut -f1 -d","`; alrm=`echo ${i} | cut -f2 -d","`; ./next.sh challenge/set-p/$rec $alrm; done

MATLAB='matlab -nodisplay -nodesktop -nosplash -r '
RECORD=$1

# Parse the type of alarm from the record header file 
# it needs to be one of the following:
#  'Asystole'
#  'Bradycardia'
#  'Tachycardia'
#  'Ventricular_Tachycardia'
#  'Ventricular_Flutter'
ALARM=`grep -m1 '^#' $RECORD.hea | tr -d'#\r'`


STR="${MATLAB} \"try result=challenge('$RECORD','$ALARM');catch display(lasterr); end; quit;\" 2>&1"
echo "$STR"
eval ${STR} | tee -a matlab.log
