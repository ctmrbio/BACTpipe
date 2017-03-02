#!/usr/bin/env python

'''
asseblyStats.py fasta-file
This function will calculate statistics of a FASTA file useful for evaluating an assembly
The input must be FASTA format. 
Created on 17 nov 2011

@author: Fredrik H Karlsson
'''
from Bio import SeqIO
import numpy
import sys
import csv
import re
import os

file=sys.argv[1]

def N50(numList):
    numList.sort()
    half=sum(numList)/2
    cumsum=numpy.cumsum(numList)
    return numList[numpy.searchsorted(cumsum,sum(numList)/2,side='right')]

def SeqHist(file):
	sizes = [len(rec) for rec in SeqIO.parse(open(file), "fasta")]  
	## before implementation: return file, len(sizes),sum(sizes),min(sizes),max(sizes),numpy.mean(sizes),int(numpy.median(sizes)), N50(sizes) 
	## Implementation: Save the results in an array and return this array
	result = []
	result.extend([file,len(sizes),sum(sizes),min(sizes),max(sizes),numpy.mean(sizes),int(numpy.median(sizes)),N50(sizes)])
	return result
a=SeqHist(file)
## before implementation: print 'Filename, number of sequences, total length, min length, max length, mean length, median length, N50 \n'
## before implementation: print a
## Implementation: Write the output results in a "csv" file
## comma separated
header = "Filename,number of sequences,total length,min length,max length,mean length,median length,N50"
title=re.split('\,', header)
blank_file = ""
output_write = open(sys.argv[2], "ab+")

with output_write as out:
	csv_file = csv.writer(out, delimiter=',')
	out.seek(0) #ensure you're at the start of the file
	first_char = out.read(1) #get the first character
	if not first_char:
		csv_file.writerow(title)
	#if blank_file == "True":
	#	csv_file.writerow(title)
	#else:
	csv_file.writerow(a)
