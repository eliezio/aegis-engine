#!/bin/bash

# TODO (fdegir): This script could be enhanced to provide full installation functionality
# by parsing arguments and executing actual engine deploy.sh with the arguments but left for later
echo "Info  : Dependencies are extracted to $DESTINATION_FOLDER"
echo "Info  : Please navigate to $DESTINATION_FOLDER/git/engine/engine folder and issue deployment command"
echo "        You can get help about the engine usage by issuing command ./deploy.sh -h"
echo "        Do not forget to specify PDF and IDF file locations using -p and -i arguments!"
echo "Info  : Done!"
