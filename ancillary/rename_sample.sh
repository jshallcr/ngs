#!/bin/bash

# Copyright (c) 2015 Jamie Shallcross and Junhyong Kim, University of
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

FROM=$1
TO=$2

pushd analyzed/$FROM
for dir in *; do
    case $dir in
	log)
	    for logfile in log/*.log; do
		sed "s/$FROM/$TO/g" $logfile > $logfile.tmp
		mv $logfile.tmp $logfile
	    done
	    ;;
	star)
	    rename "$FROM" "$TO" star/*
	    sed "s/$FROM/$TO/g" star/Log.out > star/Log.tmp
	    mv star/Log.tmp star/Log.out
	    ;;
	htseq)
	    rename "$FROM" "$TO" htseq/*
	    ;;
	blast)
	    rename "$FROM" "$TO" blast/*
	    ;;
	fastqc)
	    rename "$FROM" "$TO" fastqc/*
	    ;;
	trim)
	    rename "$FROM" "$TO" trim/*
	    ;;
	blastdb)
	    rename "$FROM" "$TO" blastdb/*
	    ;;
	*)
	    rename "$FROM" "$TO" dir/*
	    for f in dir/*; do
		if [[ `file $f | grep 'text'` ]]; then
		    sed "s/$FROM/$TO/g" $f > $f.tmp
		    mv $f.tmp $f
		fi
	    done
	    ;;
    esac
done
popd
mv analyzed/$FROM analyzed/$TO
mv raw/$FROM raw/$TO

