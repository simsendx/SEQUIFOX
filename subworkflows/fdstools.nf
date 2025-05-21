

include { SAMTOOLS_BAMTOFQ                                 } from '../modules/samtools/bamtofq/main'
include { FDSTOOLS_PIPELINE                                } from '../modules/fdstools/pipeline/main'
include { FDSTOOLS_STUTTERMARK                             } from '../modules/fdstools/stuttermark/main'


workflow FDSTOOLS {

    take:
    consensus_bam
    library_file
    ini_file


    main:

    SAMTOOLS_BAMTOFQ(consensus_bam)

    FDSTOOLS_PIPELINE(SAMTOOLS_BAMTOFQ.out.fastq, ini_file, library_file)

    FDSTOOLS_STUTTERMARK(FDSTOOLS_PIPELINE.out.csv, library_file)

}