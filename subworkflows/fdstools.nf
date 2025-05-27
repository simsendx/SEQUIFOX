//
// RUN FDSTOOLS PIPELINE
//

include { SAMTOOLS_BAMTOFQ                                 } from '../modules/samtools/bamtofq/main'
include { FDSTOOLS_PIPELINE                                } from '../modules/fdstools/pipeline/main'
include { FDSTOOLS_STUTTERMARK                             } from '../modules/fdstools/stuttermark/main'

workflow FDSTOOLS {

    take:
    consensus_bam
    library_file
    ini_file

    main:
    ch_versions = Channel.empty()

    SAMTOOLS_BAMTOFQ(consensus_bam)
    ch_versions = ch_versions.mix(SAMTOOLS_BAMTOFQ.out.versions)

    FDSTOOLS_PIPELINE(SAMTOOLS_BAMTOFQ.out.fastq, ini_file, library_file)
    ch_versions = ch_versions.mix(FDSTOOLS_PIPELINE.out.versions)

    FDSTOOLS_STUTTERMARK(FDSTOOLS_PIPELINE.out.csv, library_file)
    ch_versions = ch_versions.mix(FDSTOOLS_STUTTERMARK.out.versions)

    emit:
    versions = ch_versions
}