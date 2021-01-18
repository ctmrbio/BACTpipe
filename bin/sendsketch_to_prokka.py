#!/usr/bin/env python3
from sys import argv, exit
import argparse

"""This script identifies the top ranked genus in output from sendsketch.sh from BBMap.

Script was developed for internal use in the Nextflow pipeline BACTpipe.
"""

def parse_args():
    """Parse command line arguments.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-s", "--sketch",
        required=True,
        help="Path to sendsketch.sh output file (txt)")
    parser.add_argument("-S", "--stain", 
        required=True,
        help="Path to text file containing gram staining classifications in "
            "two-column tab separated format (Genus<TAB>Stain)")
    parser.add_argument("-p", "--profile", 
        required=True,
        help="Path to TSV file with profile information")

    if len(argv) < 2:
        parser.print_help()
        exit(1)

    args = parser.parse_args()

    return args


def parse_stain_database(stain_file):
    """Parse gram stain database into dictionary for quick lookups.
    """
    stain_db = {}
    with open(stain_file, "r") as stain:
        for line in stain:
            genus, stain = line.split("\t")
            stain_db[genus.] = stain
    return stain_db


def parse_sendsketch(sketch_file, stain_db):
    """Parse sendsketch.sh output and output if sample is contaminated or not"""

    with open(sketch_file, "r") as sketch:
        sketch_lines = sketch.readlines()

        if not sketch_lines[2].startswith("WKID\t"):
            print("ERROR: sketch file '{}' does not appear to contain valid sendsketch.sh output".format(args.sketch))
            exit(1)

        genus_one_line = sketch_lines[3]
        try:
            genus_one = genus_one_line.split("\t")[11].split(" ")[0]
            species_one = genus_one_line.split("\t")[11].split(" ")[1]
        except ValueError as e:
            print("ERROR: Could not parse line 4 of '{}':\n{}".format(args.sketch, genus_one_line))
            exit(1)

        try:
            genus_two_line = sketch_lines[4]
            genus_two = genus_two_line.split("\t")[11].split(" ")[0]
        except ValueError as e:
            print("ERROR: Could not parse line 5 of '{}':\n{}".format(args.sketch, genus_two_line))

        if len(genus_two) == 0 or genus_one == genus_two:
            genus = genus_one
            output_species = species_one.rstrip()
            output_stain = stain_db.get(genus, "Not_in_list")
        else:
            genus = "Multiple"
            output_species = "taxa"
            output_stain = "Contaminated"

    return output_species, genus, output_stain


if __name__ == "__main__":
    args = parse_args()

    stain_db = parse_stain_database(args.stain)
    output_species, genus, output_stain = parse_sendsketch(args.sketch, stain_db)

    with open(args.profile, "w") as f:
        f.writelines(output_stain + "\t" + genus + "\t" + output_species)

    print(output_stain+"\t"+genus+"\t"+output_species)
