# SEQUIFOX

Based on [UMIec_forensics](https://github.com/sfilges/UMIec_forensics/tree/main).

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=24.0.4`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command.

```bash
nextflow run simsendx/sequifox
```



## Tools used

- [AdapterRemoval](https://github.com/MikkelSchubert/adapterremoval)
- [FLASH](https://github.com/Jerrythafast/FLASH-lowercase-overhang?tab=readme-ov-file); for details, see the [paper](https://academic.oup.com/bioinformatics/article/27/21/2957/217265?login=false).
- [FASTP](https://github.com/OpenGene/fastp) as an alternative to adapterremoval and FLASH; for details, see the [paper](https://academic.oup.com/bioinformatics/article/34/17/i884/5093234?login=false)
- [FDStools](https://www.fdstools.nl/tools.html)
- Modified version of [UMIErrorCorrect](https://github.com/stahlberggroup/umierrorcorrect/)

### Generate container images

Nextflow uses containers natively and these provide many additional
benefits, including easy redistribution, dependency management and
stability.

To create a container image for the tools which are not found in common
repositories, such as quay.io, run the following (if using podman) 
using the dockerfiles in the assets folder of this repository:

#### fdstools
```bash
podman build -f fdstools.dockerfile -t fdstools:2.1.1
```

#### FLASH
```bash
podman build -f flash.dockerfile -t flash:1.2.11
```

The images can now be run using `podman run localhost/<tag>` where
the tag is the name specified with `-t`.