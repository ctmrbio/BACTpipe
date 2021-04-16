#!/usr/bin/env python3
from sys import argv, exit, stderr
from collections import defaultdict
import argparse

"""Identify top ranked genus in output report from Kraken2.

Script was developed for internal use in the Nextflow pipeline BACTpipe.
"""

def parse_args():
    """Parse command line arguments.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-r", "--kreport",
        required=True,
        help="Path to Kraken2 report output file (txt/kreport)")
    parser.add_argument("-m", "--min-proportion",
        type=float,
        default=50.00,
        help="Minimum proportion on species level [%(default)s].")
    parser.add_argument("-g", "--gramstains", 
        help="Path to text file containing gram staining classifications in "
            "two-column tab separated format (Genus<TAB>Stain)")

    if len(argv) < 2:
        parser.print_help()
        exit(1)

    args = parser.parse_args()

    return args


def parse_gramstains(gramstains):
    gramstain_db = defaultdict(lambda: "Unknown")
    try:
        with open(gramstains) as f:
            for line in f:
                genus, gramstain = line.rstrip().split("\t")
                gramstain_db[genus] = gramstain
    except TypeError as e:
        print("WARNING: No gramstain database specified, gramstain set to Unknown", file=stderr)
    return gramstain_db


def parse_kreport(kreport_file):
    with open(kreport_file) as f:
        for line_no, line in enumerate(f, start=1):
            try:
                (clade_fraction, clade_fragments, 
                    taxon_fragments, rank, taxid, name) = line.strip().split("\t")
            except ValueError as e:
                print(f"WARNING: Could not parse line {line_no}, ignoring...", file=stderr)
                continue

            try:
                clade_fraction = float(clade_fraction)
            except ValueError as e:
                print(f"WARNING: Could not interpret {clade_fraction} on row {line_no} as float, ignoring...", file=stderr)
                continue

            if rank == "S":
                clean_name = name.strip().split()[:2]
                yield clade_fraction, clean_name


def classify(detected_species, min_proportion, gramstain_db):
    taxon_names = [
            species for proportion, species in 
            filter(lambda x: x[0] > min_proportion, detected_species)
    ]

    output_genus = "Unknown"
    output_species = "unknown"

    genera = set(genus for genus, species in taxon_names)
    if len(genera) > 1:
        output_genus = "Mixed"
    elif len(genera) == 1:
        output_genus = genera.pop()

    species = set(species for genus, species in taxon_names)
    if (len(species) > 1) and output_genus:
        output_species = "spp."
    elif len(species) == 1:
        output_species = species.pop()

    output_gramstain = gramstain_db.get(output_genus, "Unknown")

    return output_genus, output_species, output_gramstain


if __name__ == "__main__":
    args = parse_args()

    gramstain_db = parse_gramstains(args.gramstains)
    detected_species = list(parse_kreport(args.kreport))
    genus, species, gramstain = classify(detected_species, args.min_proportion, gramstain_db)

    print(genus, species, gramstain, sep="\t")

