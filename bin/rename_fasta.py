#!/usr/bin/env python3
'''Rename contigs of a FASTA file with incremental count.'''

from sys import argv, exit
import argparse
import logging

logger = logging.getLogger(__name__)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-i', '--input', help='Path to input FASTA file', required=True)
    parser.add_argument('-p', '--prefix', help='FASTA header prefix before integer count', type=str, default='')
    parser.add_argument('-o', '--output', help='Path to output FASTA file', required=True)
    
    if len(argv) < 2:
        parser.print_help()
        exit(1)
    
    return parser.parse_args()


def main(input_filename, output_filename, header_prefix):
    args = parse_args()
    
    logger.info('Processing {}...'.format(input_filename))
    count = 1
    with open(input_filename, 'r') as fasta_in, open(output_filename, 'w') as fasta_out:
        for line in fasta_in:
            if line.startswith('>'):
                contig_id = '>' + header_prefix + str(count) + '\n'
                fasta_out.write(contig_id)
                count += 1
            else:
                fasta_out.write(line)

    logger.info('Wrote {0} contigs to "{1}".'.format(count, output_filename))


if __name__ == '__main__':
    args = parse_args()
    main(args.input, args.output, args.prefix)
