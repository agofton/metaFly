#!/bin/bash

####
#
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params & help
hmessage=""
usage="Usage: $(basename "$0")"

while getopts hi:o:j:t:n:c: option
do
	case "${option}"
	in
		h) echo "$hmessage"
		   echo "$usage"
		   exit;;
		i) indir=$OPTARG;;
		o) outdir=$OPTARG;;
		j) jobname=$OPTARG;;
		t) max_time=$OPTARG;;
		n) njobs=$OPTARG;;
		c) njobs_at_once=$OPTARG;;
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))

#set vars

# make dirs

# make indexes

