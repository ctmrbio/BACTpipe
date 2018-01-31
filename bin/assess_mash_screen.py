#!/usr/bin/env python3
"""
Assess MASH screening results.
"""
__author__ = "Fredrik Boulund"
__date__ = "2017"
__version__ = "0.5.0b"

from sys import argv, exit, stdout
from collections import namedtuple
import argparse
import logging
import os

MashHit = namedtuple("MashHit", "identity shared_hashes median_multiplicity p_value query comment classification_score".split())

def parse_args():

    desc = "{desc} Copyright (c) {year} {author}.".format(desc=__doc__, year=__date__, author=__author__)
    epilog = "{doc}Version {ver}.".format(doc=__doc__, ver=__version__)
    parser = argparse.ArgumentParser(description=desc, epilog=epilog)
    parser.add_argument("screen", 
            help="MASH screen output.")
    parser.add_argument("-m", "--min-identity", metavar="ID", type=float,
            default=0.85,
            help="Minimum identity [%(default)s].")
    parser.add_argument("-c", "--classification-score-threshold-modifier", 
            metavar="c", type=float, dest="modifier",
            default=0.20,
            help="Minimum classification score is computed as the classification score of the top ranking hit minus the modifier [%(default)s].")
    parser.add_argument("-i", "--ignore", metavar="STRING", dest="ignore",
            default="phage,plasmid,virus",
            help="Ignore matches to genomes containing STRING "
                 "(multiple strings can be separated by comma) [%(default)s].")
    parser.add_argument("-g", "--gram", metavar="FILENAME", dest="gram",
            default="",
            help="Path to gram positive/negative assignments of genera (two-column: genus-{pos,neg}) [%(default)s].")
    parser.add_argument("-p", "--pipeline", action="store_true",
            default=False,
            help="Simplify output to stdout (just PASS/FAIL) for use in pipelines. Do not use without specifying --outfile [%(default)s].")
    parser.add_argument("-o", "--outfile", metavar="FILENAME", 
            default="", 
            help="Output filename [%(default)s].")

    dev = parser.add_argument_group("Developer options")
    dev.add_argument("--loglevel", 
            choices=["INFO","DEBUG"],
            default="INFO",
            help="Set logging level [%(default)s].")

    if len(argv) < 2:
        parser.print_help()
        exit(1)

    args = parser.parse_args()

    # Configure logging
    if args.loglevel == "INFO":
        loglevel = logging.INFO
    else:
        loglevel = logging.DEBUG

    logging.basicConfig(level=loglevel)

    return args 


def parse_screen(screen_file):
    with open(screen_file) as f:
        for line_number, line in enumerate(f, start=1):
            try:
                (identity, shared_hashes_pair, median_multiplicity, 
                        p_value, query, comment) = line.strip().split("\t")
                shared_hashes, total_hashes = map(int, shared_hashes_pair.split("/"))
                classification_score = float(identity) * (shared_hashes / total_hashes)
                mash_hit = MashHit(float(identity), 
                                   (shared_hashes, total_hashes),
                                   int(median_multiplicity),
                                   float(p_value),
                                   query,
                                   comment,
                                   classification_score)

            except ValueError:
                log.error("Could not parse line %s:\n %s", line_number, line)
            yield mash_hit


def get_top_hits(mash_hits, min_identity=0.85, classification_score_threshold_factor=0.15):
    """
    Yield top ranked MASH screen hits.
    """

    sorted_mash_hits = sorted(mash_hits, key=lambda h: h.classification_score, reverse=True)
    classification_score_threshold = sorted_mash_hits[0].classification_score - classification_score_threshold_factor

    logging.debug("Best match: %s", sorted_mash_hits[0])
    for hit in sorted_mash_hits:
        pass_identity = hit.identity > min_identity
        pass_classification_score = hit.classification_score >= classification_score_threshold
        if pass_identity and pass_classification_score:
            logging.debug("%s passed classification. min_identity=%s, classification_score_threshold=%s", hit, min_identity, classification_score_threshold)
            yield hit
        else:
            logging.debug("%s failed classification. min_identity=%s, classification_score_threshold=%s", hit, min_identity, classification_score_threshold)


def determine_same_species(hits, ignore_set):
    """
    Determine if hits are from the same species.
    """
    if not isinstance(hits, list):
        hits = list(hits)
    found_species = set()
    for hit in hits:
        ignore_matches = [ignore_string in hit.comment for ignore_string in ignore_set]
        if any(ignore_matches):
            continue
        if hit.comment.startswith("["):
            splithit = hit.comment.split("]")[1]
        else:
            splithit = " ".join(hit.comment.split())
        found_species.add(" ".join(splithit.split()[1:3]))

    if len(found_species) > 1:
        return False, found_species
    else:
        return True, found_species


def parse_gram_stains(gram_file):
    """
    Produce a simple lookup dictionary for genus:gram_stain.
    """
    gram_stain = {}
    if not gram_file:
        return gram_stain
    with open(gram_file) as f:
        for line in f:
            genus, gram = line.strip().split()
            gram_stain[genus] = gram
    return gram_stain


if __name__ == "__main__":
    args = parse_args()
    sample_name = os.path.basename(args.screen).split(".")[0]
    ignore_set = set(args.ignore.split(","))
    gram_stains = parse_gram_stains(args.gram)
    top_hits = list(get_top_hits(parse_screen(args.screen), 
                                 min_identity=args.min_identity, 
                                 classification_score_threshold_factor=args.modifier,
                                 ))
    single_species, found_species = determine_same_species(top_hits, ignore_set=ignore_set)
    if args.outfile:
        outfile = open(args.outfile, 'w')
    else:
        outfile = stdout
    if single_species:
        genus = list(found_species)[0].split()[0]
        gram_stain = gram_stains.get(genus, "")
        if args.pipeline:
            print("PASS", end="")
        print("{}\t{}\t{}\t{}".format(sample_name, "PASS", gram_stain, list(found_species)[0]), file=outfile)
        exit(0)
    else:
        multiple_species_names = ", ".join(name for name in found_species)
        multiple_gram_stain = ", ".join(gram_stains.get(name.split()[0], "") for name in found_species)
        if args.pipeline:
            print("FAIL", end="")
        print("{}\t{}\t{}\t{}".format(sample_name, "FAIL", multiple_gram_stain, multiple_species_names), file=outfile)
        exit(3)
