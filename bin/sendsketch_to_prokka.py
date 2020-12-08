#!/usr/bin/env python3
import sys

sketch_file = sys.argv[1]
stain_file = sys.argv[2]

output_stain = "Not_in_list"
output_species = "taxa"
genus = "Multiple"

with open(sketch_file, "r") as sketch:
    sketch_lines = sketch.readlines()

    genus_one_line = sketch_lines[3]
    genus_one = genus_one_line.split("\t")[11].split(" ")[0]
    species_one = genus_one_line.split("\t")[11].split(" ")[1]

    genus_two_line = sketch_lines[4]
    genus_two = genus_two_line.split("\t")[11].split(" ")[0]

    if len(genus_two) == 0 or genus_one == genus_two:
        genus = genus_one
        output_species = species_one.rstrip()
        with open(stain_file, "r") as stain:
            for line in stain:
                if line.split("\t")[0] == genus:
                    output_stain = line.rstrip().split("\t")[1]
    else:
        output_stain = "Contaminated"
print(output_stain+"\t"+genus+"\t"+output_species)
