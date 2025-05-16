# SEQUIFOX




## Tools used

- [FLASH](https://github.com/Jerrythafast/FLASH-lowercase-overhang?tab=readme-ov-file)
- [FDStools](https://www.fdstools.nl/tools.html)

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
podman build -f flash.dockerfile -t fdstools:2.1.1
```