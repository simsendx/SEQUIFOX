# SEQUIFOX

SEQUIFOX is a Nextflow pipeline for ultrasensitive analysis of Unique Molecular Identifier (UMI) tagged 
sequencing data of Short Tandem Repeat (STR) in forensic genetics applications.

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=24.0.4`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/)

3. Download the pipeline and test it on a minimal dataset with a single command. For the profile choose whichever container environment you are using, e.g. docker, podman or singularity.

```bash
nextflow run simsendx/sequifox --samplesheet samplesheet.csv -profile podman
```

If running on Mac with ARM chips, add the arm profile, e.g. `nextflow run ... -profile docker,arm`.

For detailed installation instructions, see below.

### Typical start

```bash
nextflow run simsendx/sequifox -r <VERSION> -profile <PROFILE> --samplesheet ./samplesheet.csv --outdir ./my-results 
```

`-r <VERSION>` is optional but strongly recommended for reproducibility and should match the latest version of the pipeline.

`-profile <PROFILE>` is mandatory and should reflect any pipeline profile specified in the profile section.

`--samplesheet <FILE>` is mandatory and must be formated as described below.

`--outdir` is optional and be default the pipeline will create a directory called `results`in your current workding directory,

Note that the pipeline will create the following files and directories in your working directory:

```
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

### Optional parameters

`--fasta` Reference fasta, otherwise pulls igenomes hg38 (full human genome)

`--call_min_reads` Default is 3, minimum number of reads required to form a consensus read

`--library_file` Library file for FDStools, uses defaults otherwise.

`--bed_file` Bed file for UMIErrorCorrect annotation, uses defaults otherwise. Not required in fgbio workflow.

`--ini_file` Initialisation file for FDStools pipeline. uses defaults otherwise.

Default files are located in the assets folder and based on SiMSen-Seq assays.

#### Run as a background job

```bash
nextflow -bg run simsendx/sequifox <other parameters>
```

#### Alternative working directory

```bash
nextflow run simsendx/sequifox <other parameters> --work-dir <new working directory>
```

## Pipeline overview

The current pipeline operates in three phases:

1. Preprocessing
2. UMI correction
3. Annotation

### Preprocessing

The preprocessing phase imports the fastq files and checks the integrity of all specified files and parameters. Fastp is 
used to merge paired-end reads and perform adapter trimming as well as some quality filtering. Fastqc is run to generate
quality control files.

### UMI Correction

Formation of consensus reads is currently performed in two separate modes 'default' and 'fgbio'. The default mode is based on
alignment-free formation based on [UMIec_forensics](https://github.com/sfilges/UMIec_forensics/tree/main) using UMIErrorCorrect.
The other workflow is based on [FGBIO](https://github.com/fulcrumgenomics/fgbio/blob/main/docs/best-practice-consensus-pipeline.md)
best practices which uses UMI and mapping location for consensus family generation. The default piepline is run without any 
additional flag. To run the fgbio workflow, run the pipeline with `--mode fgbio`.

> [!WARNING]
> If running fgbio mode, the reference fasta will be indexed unless an existing index is provided. Indexing can take >1 hour for the entire human genome.
> If you have already generated a bwa index for the same reference, for example after running the pipeline once, you can supply
> the path to the directory containing index files with `--bwa_index`.

### Annotation

STR markers are mapped by FDStools from the UMI corrected files generated in the previous step.

## Detailed installation instructions

### Nextflow

For the most up-to-date installation instructions, please refer to the official [Nextflow docs](https://www.nextflow.io/docs/latest/install.html#installation).

Nextflow requires Bash 3.2 (or later) and Java 17 (or later, up to 24) to be installed. To see which version of Java you have, run the following command:

```bash
java -version
```

If you don’t have a compatible version of Java installed you can follow the instructions [here](https://www.nextflow.io/docs/latest/getstarted.html#installation).

1. Download Nextflow

```bash
curl -s https://get.nextflow.io | bash
```

2. Make Nextflow executable

```bash
chmod +x nextflow
```

3. Move Nextflow into an executable path. For example:

```bash
mkdir -p $HOME/.local/bin/
mv nextflow $HOME/.local/bin/
```

4. Confirm that nextflow is installed properly.

```bash
nextflow info
```

Done :)

### Container management 

Install a suitable container management tool, such as docker or podman. We will use podman as an example on Linux (Debian/Ubuntu)

```bash
sudo apt-get -y install podman
```

Installation instructions for other operating systems (Other Linux distributions, MacOS, Windows), see the [podman docs](https://podman.io/docs/installation).

### Command line help

To view all parameters that may be supplied via the command line, use the `--help` flag:

```bash
nextflow run simsendx/sequifox --help
```

## Sequencing platforms

The pipeline is intended for data generated on Illumina platforms. Data from all current Illumina systems is supported. However, during the preprocessing step, FASTP automatically trims polyG sequences from the 3' end of reads generated with NovaSeq and NextSeq platforms.

The pipelines supports single-end and paired-end reads, although using paired-end reads with a minimum overlap of `overlap_len_require` (see below) is recommended. If a significant number of reads are shorter than `--min_read_length` or do not overlap sufficiently, most or all usable data may be discarded.

It is recommended to run 300 cycles paired-end (600 cycles total), otherwise there might be insufficient overlap for long STR markers. See the
advanced options below for parameters that can be adjusted data other than the above is used.

## Troubleshooting

### Pipeline stuck or did not complete

Abort, if the pipeline seems stuck, using CTRL + C and try to resume the pipeline:

```bash
nextflow run simsendx/sequifox --samplesheet samplesheet.csv -profile podman -resume
```

Resume will use cached intermediary files, which for long pipelines allows retrying without much addtional waiting time.

### Stuck on revisions

If you get a warning like the following:

```bash
Project <pipeline> is currently stuck on revision: dev -- you need to explicitly specify a revision with the option -r in order to use it
```

This is a Nextflow error, with less-commonly seen Git ‘terminology’. What this means is that you have multiple versions of the pipeline pulled (e.g. 2.0.0, 2.1.0, 2.1.1, dev etc.), and it is not sure which one to use. Therefore, with every `nextflow run <PIPELINE>` command you should always indicate which version with `-r`.

## Performance benchmarks

TBD

## Advanced Options

### Overlap correction

By default overlapping paired reads are errorcorrected. If enabled, the following parameters determine the read correction (with default values shown):

```bash
--overlap_len_require 100        # the minimum length to detect overlapped region of PE read
--overlap_diff_limit 5           # the maximum number of mismatched bases to detect overlapped region of PE reads
--overlap_diff_percent_limit 20  # maximum percentage of mismatched bases to detect overlapped region of PE reads
```

This can be disabled by setting `--correction false`. 

## Configuring runs on (cloud) compute clusters

TODO: Add examples of custom config files for different cluster environments

## Tools used

- [FASTP](https://github.com/OpenGene/fastp) as an alternative to adapterremoval and FLASH used in the original pipeline UMIec_forensics; for details, see the [paper](https://academic.oup.com/bioinformatics/article/34/17/i884/5093234?login=false)
- [FDStools](https://www.fdstools.nl/tools.html)
- Modified version of [UMIErrorCorrect](https://github.com/stahlberggroup/umierrorcorrect/)
- [FGBIO](https://github.com/fulcrumgenomics/fgbio/blob/main/docs/best-practice-consensus-pipeline.md); alternative tools for consensus read formation.

- [AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval) *NOTE!* Not used in current iteration of the pipeline.
- [FLASH](https://github.com/Jerrythafast/FLASH-lowercase-overhang?tab=readme-ov-file); for details, see the [paper](https://academic.oup.com/bioinformatics/article/27/21/2957/217265?login=false). *NOTE!* Not used in current iteration of the pipeline.


## Acknowledgements