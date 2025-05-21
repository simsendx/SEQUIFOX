# SEQUIFOX



## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=24.0.4`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/)

3. Download the pipeline and test it on a minimal dataset with a single command. Does not work for private repository!

For the profile choose whichever container environment you are using, e.g. docker, podman or singularity.

```bash
nextflow run simsendx/sequifox --samplesheet <path_to_samplesheet> -profile podman
```

For private respositories clone the repo and call ´main.nf´ directly

```bash
nextflow run main.nf --samplesheet <path_to_samplesheet> -profile podman
```

If running on Mac with ARM chips, add the arm profile, e.g. `nextflow run ... -profile docker,arm`.

### Typical start

```bash
nextflow run nf-core/sarek -r <VERSION> -profile <PROFILE> --samplesheet ./samplesheet.csv --outdir ./my-results 
```

`-r <VERSION>` is optional but strongly recommended for reproducibility and should match the latest version.

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

`--fasta` Reference fasta, otherwise pulls igenomes hg38
`--call_min_reads` Default is 3, minimum number os reads required to form a consensus read
`--library_file` Library file for FDStools, uses default otherwise.
`--bed_file` Bed file for UMIErrorCorrect annotation, uses default otherwise. Not required in fgbio workflow.
`--ini_file` Initilisation file for FDStools pipeline. uses default otherwise.

Default files are located in the assets folder.


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

*NOTE!* If running fgbio mode, the reference fasta will be indexed every time, which can take ~1 hour if using the entire human genome.
This will be updated in the future!

### Annotation

STR markers are mapped by FDStools from the UMI corrected files generated in the previous step.

## Tools used

- [AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval)
- [FLASH](https://github.com/Jerrythafast/FLASH-lowercase-overhang?tab=readme-ov-file); for details, see the [paper](https://academic.oup.com/bioinformatics/article/27/21/2957/217265?login=false).
- [FASTP](https://github.com/OpenGene/fastp) as an alternative to adapterremoval and FLASH; for details, see the [paper](https://academic.oup.com/bioinformatics/article/34/17/i884/5093234?login=false)
- [FDStools](https://www.fdstools.nl/tools.html)
- Modified version of [UMIErrorCorrect](https://github.com/stahlberggroup/umierrorcorrect/)
- [FGBIO](https://github.com/fulcrumgenomics/fgbio/blob/main/docs/best-practice-consensus-pipeline.md)

### Generate container images

Nextflow uses containers natively and these provide many additional
benefits, including easy redistribution, dependency management and
stability.

To create a container image for the tools which are not found in common
repositories, such as quay.io, run the following (if using podman) 
using the dockerfiles in the assets folder of this repository:

#### fdstools
```bash
podman build -f fdstools.dockerfile -t fdstools:2.1.1 --platform linux/amd64
```

#### FLASH
```bash
podman build -f flash.dockerfile -t flash:1.2.11 --platform linux/amd64
```

#### UMIErrorCorrect
```bash
podman build -f umierrorcorrect.dockerfile -t umierrorcorrect:0.29 --platform linux/amd64
```

The images can now be run using `podman run localhost/<tag>` where
the tag is the name specified with `-t`. The local image needs to be 
specified in the config file for the corresponsing nextflow process.