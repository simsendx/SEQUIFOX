//
// UMIErrorCorrect workflow
//

include { SAMTOOLS_REHEADER                                  } from './modules/samtools/reheader/main'
include { PICARD_FASTQTOSAM as PICARD_FASTQTOBAM             } from './modules/picard/fastqtosam/main'

include { UMIERRORCORRECT_PREPROCESSING as PREPROCESSING     } from './modules/umierrorcorrect/preprocessing/main'
include { UMIERRORCORRECT_UMIERRORCORRECT as UMIERRORCORRECT } from './modules/umierrorcorrect/umierrorcorrect/main'


workflow UMIEC {

    // Preprocessing for UMI error correction
    PREPROCESSING(ch_reads, params.umi_length, params.spacer_length)

    // Convert fastq to bam (alignment free)
    PICARD_FASTQTOBAM(ch_reads)

    // REHEADER
    SAMTOOLS_REHEADER(PICARD_FASTQTOBAM.out.bam, "CHR12", 10)

    // Run UMIErrorCorrect
    UMIERRORCORRECT(SAMTOOLS_REHEADER.out.bam, params.bed_file, params.ref_genome, params.consensus_method)
    
}