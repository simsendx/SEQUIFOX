

include { FLASH                 } from "./modules/flash/main"
include { FDSTOOLS_PIPELINE     } from "./modules/fdstools/pipeline/main"
include { FDSTOOLS_TSSV         } from "./modules/fdstools/tssv/main"
include { FDSTOOLS_STUTTERMARK  } from "./modules/fdstools/stuttermark/main"
include { FASTQTOBAM            } from "./modules/fastqtobam/main"
include { UMIERRORCORRECT       } from "./modules/umierrorcorrect/main"


workflow SEQUIFOX {

    take:
    samplesheet
    library_file


    main:

    ch_fastqs = fromSampleheet()

    // If paired ends, combine reads into single reads using FLASH
    FLASH(ch_fastqs)


    // Preprocessing


    // Alignment of reads to markers by TSSV
    FDSTOOLS_TSSV(PREPROCESSING.out.fastq, library_file)

    // Convert to BAM
    FASTQTOBAM(FDSTOOLS_TSSV.out.aligned)


    // UMIErrorCorrect
    UMIERRORCORRECT(FASTQTOBAM.out.bam)

    //



    emit:

}