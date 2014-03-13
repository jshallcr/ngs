#!/bin/bash -e

# Copyright (c) 2012,2013, Stephen Fisher and Junhyong Kim, University of
# Pennsylvania.  All Rights Reserved.
#
# You may not use this file except in compliance with the Kim Lab License
# located at
#
#     http://kim.bio.upenn.edu/software/LICENSE
#
# Unless required by applicable law or agreed to in writing, this
# software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License
# for the specific language governing permissions and limitations
# under the License.

##########################################################################################
# Adding new processing step:
# 1. create a shell script containing the following elements ("COMMAND" should be a unique command name")
#    section: SOURCE MODULES HERE
#
# 2. ngsUsage_COMMAND  --  one line command usange and description
#    section: ADD MODULE USAGE HERE
#
# 3. ngsHelp_COMMAND  --  expanded command help
#    section: ADD MODULE HELP HERE
#
# 4. ngsArgs_COMMAND()  --  function for processing command line arguments
#    section: ADD MODULE ARGUMENT FUNCTION HERE
#
# 5. ngsCmd_COMMAND()  --  function that performs command operation
#    section: ADD MODULE COMMAND FUNCTIONS HERE
##########################################################################################

VERSION=2.0.0-alpha

# each module should output a tab-delimited list of file and program
# version information. This file should have two lines, the first line
# being header information and the second line being the versions. The
# prnVersion() command should be used to generate this file. This file
# will live in the respective module subdirectory (ie
# $SAMPLE/MODULE/VERSION)
VERSION_FILE="VERSION"

# all commands will be output to this file as a report of what was
# done. The file will be located in the $SAMPLE directory.
JOURNAL="analysis.log"

DEBUG=false   # disable commands when true, use to see what commands would be run.

# output every line of code to the console when running
#if "$DEBUG"; then set -x

# this is the location of the demultiplexed files, with each sample in a separate subdirectory named with the sample ID.
RAW=raw

# this is the place where analyzed data will be stored. Each sample will be put into a separate subdirectory
ANALYZED=analyzed

# location of genomic databases and library files
REPO_LOCATION=/lab/repo/resources
BOWTIE_REPO=$REPO_LOCATION/bowtie
RUM_REPO=$REPO_LOCATION/rum2
STAR_REPO=$REPO_LOCATION/star
HTSEQ_REPO=$REPO_LOCATION/htseq
SNP_REPO=$REPO_LOCATION/snp

# make comparisons case insensitive. Need to use [[ and ]] in if
# conditionals, rather than [ and ].
shopt -s nocasematch

# cause an error to happen if trying to use an unset variable. We
# don't use the -u option when launching bash above as that may cause
# bash initialization scripts to error.
set -o nounset

###############################################################################################
# PROCESS COMMAND ARGUMENTS

 
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@ 1. SOURCE MODULES HERE               @@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

source ngs_HELP.sh
source ngs_INIT.sh
source ngs_FASTQC.sh
source ngs_BLAST.sh
source ngs_BOWTIE.sh
source ngs_TRIM.sh
source ngs_STAR.sh
source ngs_RUM.sh
source ngs_RUMSTATUS.sh
source ngs_POST.sh
source ngs_BLASTDB.sh
source ngs_HTSEQ.sh
source ngs_SNP.sh
source ngs_SPAdes.sh
source ngs_RSYNC.sh
source ngs_STATS.sh
source ngs_PIPELINE.sh
source ngs_VERSION.sh


###############################################################################################
# HELP FUNCTIONS


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@ 2. ADD MODULE USAGE HERE             @@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
usage=$ngsUsage_HELP
usage+=$ngsUsage_INIT
usage+=$ngsUsage_FASTQC
usage+=$ngsUsage_BLAST
usage+=$ngsUsage_BOWTIE
usage+=$ngsUsage_TRIM
usage+=$ngsUsage_STAR
usage+=$ngsUsage_RUM
usage+=$ngsUsage_RUMSTATUS
usage+=$ngsUsage_POST
usage+=$ngsUsage_BLASTDB
usage+=$ngsUsage_HTSEQ
usage+=$ngsUsage_SNP
usage+=$ngsUsage_SPAdes
usage+=$ngsUsage_RSYNC
usage+=$ngsUsage_STATS
usage+=$ngsUsage_PIPELINE
usage+=$ngsUsage_VERSION

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@ 3. ADD MODULE HELP HERE              @@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

printHelp() {
     case $1 in
         'help') echo -e $ngsHelp_HELP;;
		 'init') echo -e $ngsHelp_INIT;;
		 'fastqc') echo -e $ngsHelp_FASTQC;;
		 'blast') echo -e $ngsHelp_BLAST;;
		 'bowtie') echo -e $ngsHelp_BOWTIE;;
		 'trim') echo -e $ngsHelp_TRIM;;
		 'star') echo -e $ngsHelp_STAR;;
		 'rum') echo -e $ngsHelp_RUM;;
		 'rumstatus') echo -e $ngsHelp_RUMSTATUS;;
		 'post') echo -e $ngsHelp_POST;;
		 'blastdb') echo -e $ngsHelp_BLASTDB;;
		 'htseq') echo -e $ngsHelp_HTSEQ;;
		 'snp') echo -e $ngsHelp_SNP;;
		 'spades') echo -e $ngsHelp_SPAdes;;
		 'rsync') echo -e $ngsHelp_RSYNC;;
		 'stats') echo -e $ngsHelp_STATS;;
		 'pipeline') echo -e $ngsHelp_PIPELINE;;
		 'version') echo -e $ngsHelp_VERSION;;

		 *) echo -e $usage;;
	 esac
}


###############################################################################################
# PROCESS COMMAND ARGUMENTS


# if no args then print out usage
if [ $# -lt 1 ]; then
	echo -e $usage
	exit 0
fi

COMMAND=$1
shift  # shift removes $1 (ie COMMAND) from the argument list

SE=false  # default is paired-end

# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@ 4. ADD MODULE ARGUMENT FUNCTION HERE @@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

if [[ "$COMMAND" = "help" ]]; then ngsArgs_HELP $@; fi
if [[ "$COMMAND" = "version" ]]; then ngsArgs_VERSION $@; fi
if [[ "$COMMAND" = "init" ]]; then ngsArgs_INIT $@; fi
if [[ "$COMMAND" = "fastqc" ]]; then ngsArgs_FASTQC $@; fi
if [[ "$COMMAND" = "blast" ]]; then ngsArgs_BLAST $@; fi
if [[ "$COMMAND" = "bowtie" ]]; then ngsArgs_BOWTIE $@; fi
if [[ "$COMMAND" = "trim" ]]; then ngsArgs_TRIM $@; fi
if [[ "$COMMAND" = "star" ]]; then ngsArgs_STAR $@; fi
if [[ "$COMMAND" = "rum" ]]; then ngsArgs_RUM $@; fi
if [[ "$COMMAND" = "rumstatus" ]]; then ngsArgs_RUMSTATUS $@; fi
if [[ "$COMMAND" = "post" ]]; then ngsArgs_POST $@; fi
if [[ "$COMMAND" = "blastdb" ]]; then ngsArgs_BLASTDB $@; fi
if [[ "$COMMAND" = "htseq" ]]; then ngsArgs_HTSEQ $@; fi
if [[ "$COMMAND" = "snp" ]]; then ngsArgs_SNP $@; fi
if [[ "$COMMAND" = "spades" ]]; then ngsArgs_SPAdes $@; fi
if [[ "$COMMAND" = "rsync" ]]; then ngsArgs_RSYNC $@ $JOURNAL; fi
if [[ "$COMMAND" = "stats" ]]; then ngsArgs_STATS $@; fi
if [[ "$COMMAND" = "pipeline" ]]; then ngsArgs_PIPELINE $@; fi


# if we've gotten to this point and $SAMPLE is not set, then something went wrong and abort
if [ -z "$SAMPLE" ]; then
	echo -e "\n************************************************"
	echo -ne "ERROR: "
	echo -e `date`
	echo "Error processing command arguments."
	echo -e $usage
	exit 1
fi


###############################################################################################
# MISCELLANEOUS DEFINITIONS

JOURNAL="$SAMPLE/$JOURNAL"

# output version information to the module subdirectory. We assume the
# output directory already exists ($SAMPLE/MODULE). We expect three
# arguments: module, header, values.
prnVersion() {
	if [ $# -ne 3 ]; then prnError "prnVersion() requires 3 arguments. Only received $#. arguments"; fi

	# we can't rely on COMMAND to know the module calling this
	# function since COMMAND might be pipeline.
	outFile="$SAMPLE/$1/$VERSION_FILE"

	# append pipeline version number
	header="Pipeline\t$2"
	values="$VERSION\t$3"

	# we intentionally write over the previous file, if it exists
	echo -e $header > $outFile
	echo -e $values >> $outFile
}

# this will uniformily format the output that is put into the JOURNAL file
prnCmd() {
	if [[ $1 == *"# BEGIN:"* ]]; then
		# copy to console
		echo
		echo "##################################################################"
		echo $1
		echo -ne `date`
		echo -ne "  "
		echo $SAMPLE
		echo "##################################################################"

		echo -ne `date` >> $JOURNAL
		echo -ne "\t" >> $JOURNAL
		echo "##################################################################" >> $JOURNAL
	fi
	echo -ne `date` >> $JOURNAL
	echo -ne "\t" >> $JOURNAL
	echo -ne $1 >> $JOURNAL
	echo >> $JOURNAL
	if [[ $1 == *"# FINISHED"* ]]; then
		echo -ne `date` >> $JOURNAL
		echo -ne "\t" >> $JOURNAL
		echo "##################################################################" >> $JOURNAL

		# insert extra line between sections
		echo >> $JOURNAL

		# copy to console
		echo
		echo "##################################################################"
		echo $1
		echo -ne `date`
		echo -ne "  "
		echo $SAMPLE
		echo "##################################################################"
	fi
}

# print warning to console
prnWarning() {
	echo -e "\n************************************************" >& 2
	echo -ne "WARNING: " >& 2
	echo -e `date` >& 2
	echo -e $1 >& 2
}

# exit on error
prnError() {
	echo -e "\n************************************************" >& 2
	echo -ne "ERROR: " >& 2
	echo -e `date` >& 2
	echo -e $1 >& 2
	exit 1
}

# create output directory first. This needs to happen prior to using
# the prnCmd() function, so we can create the output file ($JOURNAL)
# that is used by prnCmd. This happens even during debugging because
# this directory is where the $JOURNAL file is located by default.
if [ ! -d $SAMPLE ]; then
	mkdir $SAMPLE
fi

# log version and run-time information
if $DEBUG; then prnCmd "# DEBUG MODE"; fi
_cmd=`basename $0`
_args=`echo $@`
prnCmd "# COMMAND: $_cmd $COMMAND $_args"

###############################################################################################
# RUN COMMANDS


# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@ 5. ADD MODULE COMMAND FUNCTIONS HERE @@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# HELP and VERSION do not have command functions.

if [[ "$COMMAND" = "init" ]]; then ngsCmd_INIT; fi
if [[ "$COMMAND" = "fastqc" ]]; then ngsCmd_FASTQC; fi
if [[ "$COMMAND" = "blast" ]]; then ngsCmd_BLAST; fi
if [[ "$COMMAND" = "bowtie" ]]; then ngsCmd_BOWTIE; fi
if [[ "$COMMAND" = "trim" ]]; then ngsCmd_TRIM; fi
if [[ "$COMMAND" = "star" ]]; then ngsCmd_STAR; fi
if [[ "$COMMAND" = "rum" ]]; then ngsCmd_RUM; fi
if [[ "$COMMAND" = "rumstatus" ]]; then ngsCmd_RUMSTATUS; fi
if [[ "$COMMAND" = "post" ]]; then ngsCmd_POST; fi
if [[ "$COMMAND" = "blastdb" ]]; then ngsCmd_BLASTDB; fi
if [[ "$COMMAND" = "htseq" ]]; then ngsCmd_HTSEQ; fi
if [[ "$COMMAND" = "snp" ]]; then ngsCmd_SNP; fi
if [[ "$COMMAND" = "spades" ]]; then ngsCmd_SPAdes; fi
if [[ "$COMMAND" = "rsync" ]]; then ngsCmd_RSYNC; fi
if [[ "$COMMAND" = "stats" ]]; then ngsCmd_STATS; fi
if [[ "$COMMAND" = "pipeline" ]]; then ngsCmd_PIPELINE; fi
