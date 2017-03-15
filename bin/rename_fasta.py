#!/usr/bin/env python

'''Rename contigs of a FASTA file with incremental count.'''

import argparse


def main():
    '''Execute renaming.'''

    # Parse arguments.
    parser = argparse.ArgumentParser(description='Rename FASTA files.', epilog='Work out those contigs.')
    parser.add_argument('-i', '--input', help='indicate input FASTA file', required=True)
    parser.add_argument('--pre', help='string pre contig count', type=str, default='')
    parser.add_argument('--pos', help='string post contig count', type=str, default='')
    parser.add_argument('-o', '--output', help='indicate output FASTA file', required=True)
    args = parser.parse_args()

    # Open FASTA.
    fasta_in = open(args.input)

    # Create FASTA output file.
    fasta_out = open(args.output, 'wb')

    # Start counter.
    count = 1

    # Parse file and write to output.
    print('Parsing %s...' % args.input)
    for line in fasta_in.readlines():
        if line.startswith('>'):
            contig_id = '>' + args.pre + str(count) + args.pos + '\n'
            fasta_out.write(contig_id)
            count += 1
        else:
            fasta_out.write(line)

    # Finish.
    fasta_out.close()
    fasta_in.close()
    print('Wrote %d contigs to %s.' % (count, args.output))


if __name__ == '__main__':
    main()
