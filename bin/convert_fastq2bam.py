#!/usr/bin/env python3
import argparse
import sys
import re
import os
import logging
import tempfile
import subprocess
import shutil
import gzip

# --- Helper functions ---

def rev_comp(seq):
    complement = {'A': 'T', 'C': 'G', 'T': 'A', 'G': 'C'}
    return "".join(complement[base] for base in reversed(seq))

def levenshtein(s1, s2):
    if len(s1) < len(s2):
        return levenshtein(s2, s1)
    if len(s2) == 0:
        return len(s1)
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    return previous_row[-1]

def search_for_flank_trim(seq, flank, rev_flank, flank_len, flank_rev_len):
    for m in re.finditer(flank, seq):
        return m.end()
    for m in re.finditer(rev_flank, seq):
        return m.end()
    for base in range(-1, -len(seq)-flank_len, -1):
        subseq = seq[base-flank_len : base]
        subseq_rev = seq[base-flank_rev_len : base]
        lev = levenshtein(subseq, flank)
        lev_rev = levenshtein(subseq_rev, rev_flank)
        if lev <= 2 or lev_rev <= 2:
            return base
    return None

def get_chr_str(bedfile):
    with open(bedfile) as fh:
        chromsomes, pos, fq_dirs = [], [], []
        for line in fh:
            line = line.rstrip().split("\t")
            chromsomes.append(line[0])
            pos.append(line[1])
            fq_dirs.append(line[3])
    return chromsomes, pos, fq_dirs

def get_flanks_lib(filename):
    flanks = {}
    with open(filename) as fh:
        found_flanks = False
        for line in fh:
            line = line.strip()
            if line.startswith("[flanks]"):
                found_flanks = True
            elif line.startswith("[") and found_flanks:  # Any new section after [flanks]
                return flanks
            elif found_flanks and not (line.startswith(";") or line.startswith("_") or line == ""):
                try:
                    key, value = line.replace(" ", "").split("=")
                    flanks[key] = value.split(",")
                except ValueError:
                    # Skip lines that don't have an '=' character
                    continue
    return flanks

def write_header(outfile, chromsomes):
    with open(outfile, "w") as outfh:
        for chrom in set(chromsomes):
            outfh.write(f"@SQ\tSN:{chrom}\tLN:10\n")

def fq2sam(infile, outfile, dir, chrom, pos, flank, flank_rev, trim_flanks):
    try:
        with gzip.open(infile, 'rt') as infh, open(outfile, "a") as outfh:
            fq_lines, count = [], 0
            flank_len, flank_rev_len = len(flank), len(flank_rev)
            for line in infh:
                fq_lines.append(line.strip())
                if len(fq_lines) == 4:
                    end = search_for_flank_trim(fq_lines[1], flank, flank_rev, flank_len, flank_rev_len) if trim_flanks else len(fq_lines[1])
                    if end is None:
                        fq_lines = []
                        continue
                    fq_lines[1], fq_lines[3] = fq_lines[1][:end], fq_lines[3][:end]
                    cigar = len(fq_lines[1])
                    sam_line = f"{fq_lines[0][1:]}\t0\t{chrom}\t{pos}\t255\t{cigar}M\t*\t0\t0\t{fq_lines[1]}\t{fq_lines[3]}\tUG:Z:{dir}\n"
                    outfh.write(sam_line)
                    fq_lines, count = [], count + 1
            logging.info(f"Found {count} reads for {dir}")
            return count
    except Exception as e:
        logging.error(f"Error processing {infile}: {str(e)}")
        return 0

def loop_fds_result(indir, outfile, chromsomes, fq_dir, pos, lib, trim_flanks=True):
    flanks = get_flanks_lib(lib)
    total_reads = 0
    for dire, chrom, position in zip(fq_dir, chromsomes, pos):
        fastq_path = f"{indir}/{dire}/paired.fq.gz"
        if os.path.exists(fastq_path):
            count = fq2sam(fastq_path, outfile, dire, chrom, position,
                   flanks[dire][1], rev_comp(flanks[dire][0]), trim_flanks)
            total_reads += count
        else:
            logging.warning(f"FASTQ file not found: {fastq_path}")
    
    logging.info(f"Total reads processed: {total_reads}")
    return total_reads

# --- Main processing function ---

def run_command(cmd, desc=None):
    """Run a command with proper logging and error checking"""
    if desc:
        logging.info(f"{desc}: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, check=True)
        if result.stdout:
            logging.debug(f"Command stdout: {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed: {' '.join(cmd)}")
        logging.error(f"Error output: {e.stderr}")
        return False

def parseArgs():
    parser = argparse.ArgumentParser(description="Converts FDStools TSSV output to BAM format.")
    parser.add_argument('-o', '--output_file', required=True, help='Output BAM file')
    parser.add_argument('-f', '--fastq', required=True, help='Path to FDStools output folder')
    parser.add_argument('-b', '--bed', required=True, help='Path to BED file')
    parser.add_argument('-l', '--Library', dest='lib', required=True, help='Path to library file')
    return parser.parse_args()

def fastq2bam(infolder, outfile, bed_file, library_file, trim_flanks=True, num_threads=1):
    # Log configuration info
    logging.info(f"Working directory: {os.getcwd()}")
    logging.info(f"Input folder: {os.path.abspath(infolder)}")
    logging.info(f"Output file: {os.path.abspath(outfile)}")
    logging.info(f"BED file: {os.path.abspath(bed_file)}")
    logging.info(f"Library file: {os.path.abspath(library_file)}")

    # Create a temporary directory for all work
    temp_dir = tempfile.mkdtemp(prefix="fastq2bam_")
    logging.info(f"Created temporary directory: {temp_dir}")
    
    try:
        # Define file paths
        sam_file = os.path.join(temp_dir, "temp.sam")
        
        # Generate SAM file
        logging.info(f"Generating SAM file: {sam_file}")
        chromosomes, pos, fq_dirs = get_chr_str(bed_file)
        write_header(sam_file, chromosomes)
        total_reads = loop_fds_result(infolder, sam_file, chromosomes, fq_dirs, pos, library_file, trim_flanks)
        
        if total_reads == 0:
            logging.error("No reads were processed. Check your input files.")
            return False
        
        # Check SAM file
        if not os.path.exists(sam_file):
            logging.error(f"SAM file was not created: {sam_file}")
            return False
        
        sam_size = os.path.getsize(sam_file)
        if sam_size == 0:
            logging.error(f"SAM file is empty: {sam_file}")
            return False
        
        logging.info(f"SAM file created successfully: {sam_file} ({sam_size} bytes)")
        
        # Convert SAM to BAM and sort in one step using samtools
        cmd = ["samtools", "sort", "-O", "bam", "-o", outfile, sam_file]
        if num_threads > 1:
            cmd.extend(["-@", str(num_threads)])
        
        if not run_command(cmd, "Converting SAM to sorted BAM"):
            # Try alternative approach if the combined command fails
            logging.info("First attempt failed, trying two-step approach...")
            
            temp_bam = os.path.join(temp_dir, "temp.bam")
            
            # Convert SAM to BAM first
            if not run_command(["samtools", "view", "-b", "-o", temp_bam, sam_file], 
                             "Converting SAM to BAM"):
                logging.error("Failed to convert SAM to BAM")
                return False
            
            # Then sort the BAM
            if not run_command(["samtools", "sort", "-o", outfile, temp_bam], 
                             "Sorting BAM"):
                logging.error("Failed to sort BAM")
                return False
        
        # Index the final BAM file
        if not run_command(["samtools", "index", outfile], "Indexing BAM"):
            logging.error("Failed to index BAM file")
            return False
        
        logging.info(f"Successfully created sorted and indexed BAM: {outfile}")
        return True
        
    finally:
        # Clean up temporary directory
        try:
            shutil.rmtree(temp_dir)
            logging.info(f"Cleaned up temporary directory: {temp_dir}")
        except Exception as e:
            logging.warning(f"Failed to clean up temporary directory {temp_dir}: {str(e)}")

def main():
    # Set up logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # Parse arguments
    args = parseArgs()
    
    # Run the main process
    success = fastq2bam(args.fastq, args.output_file, args.bed, args.lib)
    
    # Exit with appropriate status
    if not success:
        logging.error("Processing failed")
        sys.exit(1)
    else:
        logging.info("Processing completed successfully")
        sys.exit(0)

if __name__ == '__main__':
    main()