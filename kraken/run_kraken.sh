#!/bin/bash

####
#
#
# Written by Alexander Gofton, ANIC, CSIRO, 2018
# alexander.gofton@gmail.com; alexander.gofton@csiro.au
####

# set params and help/usage message
help_message=""
usage=""

while getopts hd:i:o:t:j:n:c: option
do
	case "${option}"
	in
		h) echo "$help_message"
		   echo "$usage"
	       exit;;
		d) db=$OPTARG;; 
		i) in_dir=$OPTARG;; 
		o) out_dir=$OPTARG;;
		t) time=$OPTARG;;
		j) job_name=$OPTARG;;
		n) nsamples=$OPTARG;;
		c) narrays_at_once=$OPTARG;;	
		:) printf "missing argument for  -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
	  	   exit 1;;
	   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
		   echo "$usage" >&2
		   exit 1;;
	esac
done
shift $((OPTIND - 1))









