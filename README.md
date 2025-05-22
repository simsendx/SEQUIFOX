# SEQUIFOX

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=24.0.4`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/)

3. Download the pipeline and test it on a minimal dataset with a single command. For the profile choose whichever container environment you are using, e.g. docker, podman or singularity.

```bash
nextflow run simsendx/sequifox --samplesheet <path_to_samplesheet> -profile podman
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

`--ini_file` Initilisation file for FDStools pipeline. uses defaults otherwise.

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
> If running fgbio mode, the reference fasta will be indexed every time, which can take ~1 hour if using the entire human genome.
> This will be updated in the future!

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

## Tools used

- [FASTP](https://github.com/OpenGene/fastp) as an alternative to adapterremoval and FLASH used in the original pipeline UMIec_forensics; for details, see the [paper](https://academic.oup.com/bioinformatics/article/34/17/i884/5093234?login=false)
- [FDStools](https://www.fdstools.nl/tools.html)
- Modified version of [UMIErrorCorrect](https://github.com/stahlberggroup/umierrorcorrect/)
- [FGBIO](https://github.com/fulcrumgenomics/fgbio/blob/main/docs/best-practice-consensus-pipeline.md); alternative tools for consensus read formation.

- [AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval) *NOTE!* Not used in current iteration of the pipeline.
- [FLASH](https://github.com/Jerrythafast/FLASH-lowercase-overhang?tab=readme-ov-file); for details, see the [paper](https://academic.oup.com/bioinformatics/article/27/21/2957/217265?login=false). *NOTE!* Not used in current iteration of the pipeline.


## Verified Vendors, Kits, and Assays

> [!WARNING]
> The following Vendors, Kits, and Assays are provided for informational purposes only.
> _No warranty for the accuracy or completeness of the information or parameters is implied._

| Verified | Assay      | Company           | Strand | Randomness | UMI Location     | Read Structure  | URL                                                                                                                                                                                 |
| -------- | --------------------------------------------------------- | --------------------------- | ------ | ---------- | ---------------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|        |                |         |  |      |                  |                 |                                |


## Advanced Options




## Ackknowledgements