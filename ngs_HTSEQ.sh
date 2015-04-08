#!/bin/bash

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
# INPUT: $SAMPLE/star/STAR_Unique.bam
# OUTPUT: $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt, $SAMPLE/htseq/$SAMPLE.htseq.log.txt, $SAMPLE/htseq/$SAMPLE.htseq.err.txt
# REQUIRES: HTSeq, Pysam, NumPY, runHTSeq.py
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

NGS_USAGE+="Usage: `basename $0` htseq OPTIONS sampleID    --  run HTSeq on unique mapped reads\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_HTSEQ() {
    echo -e "Usage:\n\t`basename $0` htseq [-i inputDir] [-f inputFile] [-stranded] [-introns] [-intergenic] [-lines_sines] [-id idAttr] -s species sampleID"
    echo -e "Input:\n\tsampleID/inputDir/inputFile"
    echo -e "Output:\n\tsampleID/htseq/sampleID.htseq.cnts.txt\n\tsampleID/htseq/sampleID.htseq.log.txt\n\tsampleID/htseq/sampleID.htseq.err.txt"
    echo -e "Requires:\n\tHTSeq version 0.6 or later ( http://www-huber.embl.de/users/anders/HTSeq/ )\n\tPysam ( https://pypi.python.org/pypi/pysam )\n\tdynamicRange.py ( https://github.com/safisher/ngs )"
    echo -e "Options:"
    echo -e "\t-i inputDir - location of source file (default: star)."
    echo -e "\t-f inputFile - source file (default: sampleID.star.unique.bam)."
    echo -e "\t-stranded - use strand information (default: no)."
    echo -e "\t-introns - also compute intron counts (default: no). A single GTF file is expected to contain both introns and exon. HTSeq will be run first with type=exon and a second time with type=intron. The intron counting is done using intersection-strict and the output counts will be in a separate file from the exon counts. The output file will have the suffix 'introns'."
    echo -e "\t-intergenic - also compute intergenic counts, using intersection-strict (default: no). The output file will have the suffix 'intergenic'."
    echo -e "\t-lines_sines - also compute line and sine counts, using intersection-nonempty (default: no). The output file will have the suffix 'xine'."
    echo -e "\t-id idAttr - the 'idattr' flag for HTSeq.count() which is the GTF feature that contains the feature ID (default: gene_id)."
    echo -e "\t-s species - species from repository: $HTSEQ_REPO.\n"
    echo -e "Run HTSeq using htseq-count script. This requires a BAM file as generated by either RUMALIGN or STAR (STAR by default)."
    echo -e "The following HTSeq parameter values are used for exon counting:\n \t--mode=intersection-nonempty --type=exon\n"
    echo -e "Each type of feature being counted (i.e. exons, introns, intergentic, mitochondrial, lines and sines) is run independently and simultaneously."
    echo -e "If the RESOURCES directory contains a library file called SPECIES.mito.gz then a feature count will be performed using the mitochondrial library (intersection-nonempty) and the resulting counts will be put in a file with the suffix 'mito'\n."
    echo -e "INTRON COUNTING (-introns option):"
    echo -e "When intron counting is enabled (-introns) then introns will be counted with intersection-strict. In this case three counts files will be generated:"
    echo -e "\tSampleID.htseeq.exons.cnts: exon counts"
    echo -e "\tSampleID.htseeq.introns.cnts: intron counts"
    echo -e "\tSampleID.htseeq.cnts.txt: combined counts tab delimited (gene, exons, introns, total)\n"
    echo -e "For a description of the HTSeq parameters see http://www-huber.embl.de/users/anders/HTSeq/doc/count.html#count\n"
}

##########################################################################################
# LOCAL VARIABLES WITH DEFAULT VALUES. Using the naming convention to
# make sure these variables don't collide with the other modules.
##########################################################################################

ngsLocal_HTSEQ_INP_DIR="star"
# the default for ngsLocal_HTSEQ_INP_FILE is set in ngsCmd_HTSEQ()
# because it depends on the value of $SAMPLE and $SAMPLE doesn't have
# a value until the ngsCmd_HTSEQ() function is run.
ngsLocal_HTSEQ_INP_FILE=""
ngsLocal_HTSEQ_STRANDED="no"
ngsLocal_HTSEQ_EXONS="yes"
ngsLocal_HTSEQ_INTRONS="no"
ngsLocal_HTSEQ_INTERGENIC="no"
ngsLocal_HTSEQ_xINEs="no"

# use "gene_id" by default but let users change to "gene_name" or whatever needed
ngsLocal_HTSEQ_ID_ATTR="gene_id"

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# HTSEQ args: -s value, -g value, sampleID
##########################################################################################

ngsArgs_HTSEQ() {
    if [ $# -lt 3 ]; then printHelp "HTSEQ"; fi
    
    # getopts doesn't allow for optional arguments so handle them manually
    while true; do
	case $1 in
	    -i) ngsLocal_HTSEQ_INP_DIR=$2
		shift; shift;
		;;
	    -f) ngsLocal_HTSEQ_INP_FILE=$2
		shift; shift;
		;;
	    -stranded) ngsLocal_HTSEQ_STRANDED="yes"
		shift;
		;;
	    -introns) ngsLocal_HTSEQ_INTRONS="yes"
		shift;
		;;
	    -intergenic) ngsLocal_HTSEQ_INTERGENIC="yes"
		shift;
		;;
	    -lines_sines) ngsLocal_HTSEQ_xINEs="yes"
		shift;
		;;
	    -id) ngsLocal_HTSEQ_ID_ATTR=$2
		shift; shift;
		;;
	    -s) SPECIES=$2
		shift; shift;
		;;
	    -*) printf "Illegal option: '%s'\n" "$1"
		printHelp $COMMAND
		exit 0
		;;
 	    *) break ;;
	esac
    done
    
    SAMPLE=$1
}

##########################################################################################
# RUNNING COMMAND ACTION
# Run HTSeq on uniqely mapped alignments, as generated by the POST command.
##########################################################################################

ngsCmd_HTSEQ() { 
    prnCmd "# BEGIN: HTSEQ"
    
    # make relevant directory
    if [ ! -d $SAMPLE/htseq ]; then 
	prnCmd "mkdir $SAMPLE/htseq"
	if ! $DEBUG; then mkdir $SAMPLE/htseq; fi
    fi
    
    # print version info in $SAMPLE directory
    prnCmd "# HTSeq version: python -c 'import HTSeq, pkg_resources; print pkg_resources.get_distribution(\"HTSeq\").version'"
    if ! $DEBUG; then 
	# returns: "0.5.4p5"
	ver=$(python -c "import HTSeq, pkg_resources; print pkg_resources.get_distribution(\"HTSeq\").version")
	prnVersion "htseq" "program\tversion\ttranscriptome" "htseq\t$ver\t$HTSEQ_REPO/$SPECIES.gz"
    fi
    
    # if the user didn't provide an input file then set it to the
    # default
    if [[ -z "$ngsLocal_HTSEQ_INP_FILE" ]]; then 
	ngsLocal_HTSEQ_INP_FILE="$SAMPLE.star.unique.bam"
    fi 
    # We assume that the alignment file exists

    if [ $ngsLocal_HTSEQ_EXONS = "yes" ]; then
	ngsRunHTSEQ_COUNT intersection-nonempty exon exons $ngsLocal_HTSEQ_STRANDED "" 
    fi

    if [ -f $HTSEQ_REPO/$SPECIES.mito.gz ]; then	
	ngsRunHTSEQ_COUNT intersection-nonempty exon mito $ngsLocal_HTSEQ_STRANDED mito.
    fi

    if [ $ngsLocal_HTSEQ_INTRONS = "yes" ]; then
	ngsRunHTSEQ_COUNT intersection-strict intron introns $ngsLocal_HTSEQ_STRANDED "" 	
    fi

    if [ $ngsLocal_HTSEQ_INTERGENIC = "yes" ]; then
	ngsRunHTSEQ_COUNT intersection-strict intergenic intergenic no "" 
    fi
    
    if [ $ngsLocal_HTSEQ_xINEs = "yes" ]; then
	ngsRunHTSEQ_COUNT intersection-nonempty xine lines_sines $ngsLocal_HTSEQ_STRANDED "" 
    fi

    #All runs are started in the background so they can run in parallel. Wait until they all return. 
    wait 

    prnCmd "# splitting output file into counts, log, and error files"
    # parse output into three files: gene counts ($SAMPLE.htseq.cnts.txt), 
    # warnings ($SAMPLE.htseq.err.txt), log ($SAMPLE.htseq.log.txt)
    if ! $DEBUG; then 
	# only generate error file if Warnings exist. If we run grep
	# and it doesn't find any matches then it will exit with an
	# error code which would cause the program to crash since we
	# use "set -o errexit"
	if [[ $ngsLocal_HTSEQ_EXONS = "yes" ]]; then ngsPostHTSEQ "exons."; fi
	if [[ $ngsLocal_HTSEQ_INTRONS = "yes" ]]; then ngsPostHTSEQ "introns."; fi
	if [[ $ngsLocal_HTSEQ_INTERGENIC = "yes" ]]; then ngsPostHTSEQ "intergenic."; fi
	if [[ -f $HTSEQ_REPO/$SPECIES.mito.gz ]]; then ngsPostHTSEQ "mito."; fi
	if [[ $ngsLocal_HTSEQ_xINEs = "yes" ]]; then ngsPostHTSEQ "lines_sines."; fi
    fi

    # run error checking
    if ! $DEBUG; then 
	if [[ $ngsLocal_HTSEQ_EXONS = "yes" ]]; then ngsErrorChk_HTSEQ "exons."; fi
	if [[ $ngsLocal_HTSEQ_INTRONS = "yes" ]]; then ngsErrorChk_HTSEQ "introns."; fi
	if [[ $ngsLocal_HTSEQ_INTERGENIC = "yes" ]]; then ngsErrorChk_HTSEQ "intergenic."; fi
	if [[ -f $HTSEQ_REPO/$SPECIES.mito.gz ]]; then ngsErrorChk_HTSEQ "mito."; fi
	if [[ $ngsLocal_HTSEQ_xINEs = "yes" ]]; then ngsErrorChk_HTSEQ "lines_sines."; fi
    fi
    
    prnCmd "# FINISHED: HTSEQ"
}

ngsRunHTSEQ_COUNT(){
    local MODE=$1
    local TYPE=$2
    local OUTSUFFIX=$3
    local STRANDED=$4
    local INSUFFIX=$5

    prnCmd "python -m HTSeq.scripts.count --format=bam --order=name --mode=$MODE --stranded=$STRANDED --type=$TYPE --idattr=$ngsLocal_HTSEQ_ID_ATTR $SAMPLE/$ngsLocal_HTSEQ_INP_DIR/$ngsLocal_HTSEQ_INP_FILE $HTSEQ_REPO/$SPECIES.${INSUFFIX}gz > $SAMPLE/htseq/$SAMPLE.htseq.$OUTSUFFIX.out 2>&1 &"
    if ! $DEBUG; then 
        python -m HTSeq.scripts.count --format=bam --order=name --mode=$MODE --stranded=$STRANDED --type=$TYPE --idattr=$ngsLocal_HTSEQ_ID_ATTR $SAMPLE/$ngsLocal_HTSEQ_INP_DIR/$ngsLocal_HTSEQ_INP_FILE $HTSEQ_REPO/$SPECIES.${INSUFFIX}gz > $SAMPLE/htseq/$SAMPLE.htseq.$OUTSUFFIX.out 2>&1 &
    fi

}



# $1 should be "" or "introns." or "mito."
ngsPostHTSEQ() {

    # only generate error file if Warnings exist. If we run grep
    # and it doesn't find any matches then it will exit with an
    # error code which would cause the program to crash since we
    # use "set -o errexit"
    local containsWarningsI=$(grep -c 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.${1}out)
    if [[ $containsWarningsI -gt 0 ]]; then
	prnCmd "grep 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.${1}out > $SAMPLE/htseq/$SAMPLE.htseq.${1}err.txt"
	grep 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.${1}out > $SAMPLE/htseq/$SAMPLE.htseq.${1}err.txt
	
	prnCmd "grep -v 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.${1}out > $SAMPLE/htseq/tmp.txt"
	grep -v 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.${1}out > $SAMPLE/htseq/tmp.txt
    else
	prnCmd "mv $SAMPLE/htseq/$SAMPLE.htseq.${1}out $SAMPLE/htseq/tmp.txt"
	cp $SAMPLE/htseq/$SAMPLE.htseq.${1}out $SAMPLE/htseq/tmp.txt
    fi
    
    prnCmd "echo -e 'gene\tcount' > $SAMPLE/htseq/$SAMPLE.htseq.${1}cnts.txt"
    echo -e 'gene\tcount' > $SAMPLE/htseq/$SAMPLE.htseq.${1}cnts.txt
    
    prnCmd "$GREPP '\t' $SAMPLE/htseq/tmp.txt | $GREPP -v 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' >> $SAMPLE/htseq/$SAMPLE.htseq.${1}cnts.txt"
    $GREPP '\t' $SAMPLE/htseq/tmp.txt | $GREPP -v 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' >> $SAMPLE/htseq/$SAMPLE.htseq.${1}cnts.txt
    
    prnCmd "$GREPP -v '\t' $SAMPLE/htseq/tmp.txt > $SAMPLE/htseq/$SAMPLE.htseq.${1}log.txt"
    $GREPP -v '\t' $SAMPLE/htseq/tmp.txt > $SAMPLE/htseq/$SAMPLE.htseq.${1}log.txt
    
    prnCmd "$GREPP 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' $SAMPLE/htseq/tmp.txt >> $SAMPLE/htseq/$SAMPLE.htseq.${1}log.txt"
    $GREPP 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' $SAMPLE/htseq/tmp.txt >> $SAMPLE/htseq/$SAMPLE.htseq.${1}log.txt
    
    prnCmd "rm $SAMPLE/htseq/$SAMPLE.htseq.${1}out $SAMPLE/htseq/tmp.txt"
    rm $SAMPLE/htseq/$SAMPLE.htseq.${1}out $SAMPLE/htseq/tmp.txt
}


##########################################################################################
# ERROR CHECKING. Make sure output file exists, is not effectively
# empty and warn user if HTSeq output any warnings.
##########################################################################################

# $1 should be "exons." or "introns." or "mito."
ngsErrorChk_HTSEQ() {
    prnCmd "# HTSEQ ERROR CHECKING: RUNNING"

    inputFile="$SAMPLE/$ngsLocal_HTSEQ_INP_DIR/$ngsLocal_HTSEQ_INP_FILE"
    outputFile="$SAMPLE/htseq/$SAMPLE.htseq.${1}cnts.txt"
    
    # make sure expected output file exists
    if [ ! -f $outputFile ]; then
	errorMsg="Expected HTSeq output file does not exist.\n"
	errorMsg+="\tinput file: $inputFile\n"
	errorMsg+="\toutput file: $outputFile\n"
	prnError "$errorMsg"
    fi

    # if cnts file only has 1 line then error and print contents of log file
    counts=`wc -l $outputFile | awk '{print $1}'`
    # if counts file only has one line, then HTSeq didn't work
    if [ "$counts" -eq "1" ]; then
	errormsg="htseq failed to run properly. see htseq error below:\n"
	errormsg+="\tinput file: $inputFile\n"
	errormsg+="\toutput file: $outputFile\n\n"
	errormsg+=`cat $sample/htseq/$sample.htseq.${1}log.txt`
	prnerror "$errormsg"
    fi
    
    # Check err file for errors
    if [ -s $SAMPLE/htseq/$SAMPLE.htseq.${1}err.txt ]; then
	warningMsg="Review the error file listed below to view HTSeq warnings.\n"
	warningMsg+="\tinput file: $inputFile\n"
	warningMsg+="\toutput file: $outputFile\n"
	warningMsg+="\tERROR FILE: $SAMPLE/htseq/$SAMPLE.htseq.${1}err.txt\n"
	prnWarning "$warningMsg"
    fi
    
    prnCmd "# HTSEQ ERROR CHECKING: DONE"
}

##########################################################################################
# PRINT STATS. Prints a tab-delimited list stats of interest.
##########################################################################################

ngsStats_HTSEQ() {
    if [ $# -ne 1 ]; then
	prnError "Incorrect number of parameters for ngsStats_HTSEQ()."
    fi
    
    header=""
    values=""
    
    if [ -f $SAMPLE/htseq/$SAMPLE.htseq.exons.cnts.txt ]; then 
	ngsHelperStatsHTSEQ "exons" "Gene (exons)"
    else
	# pad header and values with tabs for missing exon file.
	header="$header\t\t\t\t\t\t\t"
	values="$values\t\t\t\t\t\t\t"
    fi

    if [ -f $SAMPLE/htseq/$SAMPLE.htseq.introns.cnts.txt ]; then 
	ngsHelperStatsHTSEQ "introns" "Gene (introns)"
    else
	# pad header and values with tabs for missing introns file.
	header="$header\t\t\t\t\t\t\t"
	values="$values\t\t\t\t\t\t\t"
    fi

    if [ -f $SAMPLE/htseq/$SAMPLE.htseq.mito.cnts.txt ]; then 
	ngsHelperStatsHTSEQ "mito" "Gene (mito)"
    else
	header="$header\t\t\t\t\t\t\t"
	values="$values\t\t\t\t\t\t\t"
    fi

    if [ -f $SAMPLE/htseq/$SAMPLE.htseq.intergenic.cnts.txt ]; then 
	ngsHelperStatsHTSEQ "intergenic" "Intergenic Region"
    else
	header="$header\t\t\t\t\t"
	values="$values\t\t\t\t\t"
    fi

    if [ -f $SAMPLE/htseq/$SAMPLE.htseq.lines_sines.cnts.txt ]; then 
	# handle lines-sines differently than the rest
	ngsHelperStatsHTSEQ_LS
    else
	header="$header\t\t\t\t\t"
	values="$values\t\t\t\t\t"
    fi

    case $1 in
	header) 
	    echo "$header"
	    ;;
	
	values) 
	    echo "$values"
	    ;;
	
	*) 
	    # incorrect argument
	    prnError "Invalid parameter for ngsStats_HTSEQ() (got $1, expected: 'header|values')."
	    ;;
    esac
}

ngsHelperStatsHTSEQ() {
    # $1 = exons | introns | mito | intergenic
    # $2 = ie "gene (exons) or "intergenic region"

    if [[ $1 == "exons" ]]; then
	# total number of reads that mapped unambigously to genes
	readsCounted=$(grep -v "ERCC-" $SAMPLE/htseq/$SAMPLE.htseq.${1}.cnts.txt | awk -F '\t' '{sum += $2} END {print sum}')
	header="${header}non-ERCC Reads Counted"
	values="${values}$readsCounted"
	
	# total number of reads that mapped unambigously to ERCC controls
	erccReadsCounted=$(grep "ERCC-" $SAMPLE/htseq/$SAMPLE.htseq.${1}.cnts.txt | awk -F '\t' '{sum += $2} END {print sum}')
	header="$header\tERCC Reads Counted"
	values="$values\t$erccReadsCounted"
    else
	readsCounted=$(cat $SAMPLE/htseq/$SAMPLE.htseq.${1}.cnts.txt | awk -F '\t' '{sum += $2} END {print sum}')
	header="$header\tReads Counted (${1})"
	values="$values\t$readsCounted"
    fi

    # number of genes with at least 1 read mapped
    numGenes=$($GREPP -v "\t0$" $SAMPLE/htseq/$SAMPLE.htseq.${1}.cnts.txt | grep -v "gene" | wc -l)
    header="$header\tNum ${2}"
    values="$values\t$numGenes"
    
    # average number of reads that mapped unambigously to genes
    if [[ $numGenes -gt 0 ]]; then
	avgReadPerGene=$(($readsCounted/$numGenes))
    else
	avgReadPerGene=0
    fi
    header="$header\tAvg Read Per ${2}"
    values="$values\t$avgReadPerGene"
    
    # maximum number of reads that mapped unambigously to a single gene
    maxReadsPerGene=$(grep -v "gene" $SAMPLE/htseq/$SAMPLE.htseq.${1}.cnts.txt | awk -F '\t' '{if(max=="") {max=$2}; if($2>max) {max=$2};} END {print max}')
    header="$header\tMax Reads Per ${2}"
    values="$values\t$maxReadsPerGene"
    
    # number of reads that didn't map to a gene region
    noFeature=$(tail -5 $SAMPLE/htseq/$SAMPLE.htseq.${1}.log.txt | head -1 | awk '{print $2}')
    header="$header\tNo Feature (${1})"
    values="$values\t$noFeature"
    
    if [[ $1 != "intergenic" ]]; then

	# number of reads that completely overlapped two or more gene regions
	ambiguousMapped=$(tail -4 $SAMPLE/htseq/$SAMPLE.htseq.${1}.log.txt | head -1 | awk '{print $2}')
	header="$header\tAmbiguous Mapped (${1})"
	values="$values\t$ambiguousMapped"
	
	# compute dynamic range
	dynamicRange=$(dynamicRange.py -c $SAMPLE/htseq/$SAMPLE.htseq.${1}.cnts.txt)
	header="$header\tDynamic Range (${1})"
	values="$values\t$dynamicRange"
    fi
}

# lines and sines are handled differently.
ngsHelperStatsHTSEQ_LS() {
	# total number of reads that mapped unambigously to genes
	LINEreadsCounted=$(grep 'LINE'  $SAMPLE/htseq/$SAMPLE.htseq.lines_sines.cnts.txt | awk -F '\t' '{sum += $2} END {print sum}')
	header="$header\tLINE Reads"
	values="$values\t$LINEreadsCounted"
	
	SINEreadsCounted=$(grep 'SINE'  $SAMPLE/htseq/$SAMPLE.htseq.lines_sines.cnts.txt | awk -F '\t' '{sum += $2} END {print sum}')
	header="$header\tSINE Reads"
	values="$values\t$SINEreadsCounted"

	# number of genes with at least 1 read mapped
	numLINEs=$($GREPP -v "\t0$" $SAMPLE/htseq/$SAMPLE.htseq.lines_sines.cnts.txt | grep -v "gene" | grep 'LINE' | wc -l)
	header="$header\tNum LINEs"
	values="$values\t$numLINEs"
	
	# number of genes with at least 1 read mapped
	numSINEs=$($GREPP -v "\t0$" $SAMPLE/htseq/$SAMPLE.htseq.lines_sines.cnts.txt | grep -v "gene" | grep 'SINE' | wc -l)
	header="$header\tNum SINEs"
	values="$values\t$numSINEs"

	# number of reads that didn't map to a gene region
	noFeature=$(tail -5 $SAMPLE/htseq/$SAMPLE.htseq.lines_sines.log.txt | head -1 | awk '{print $2}')
	header="$header\tNeither LINEs nor SINEs"
	values="$values\t$noFeature"
}

