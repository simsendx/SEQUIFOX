//
// UMIErrorCorrect workflow
//
include { SAMTOOLS_FAIDX                                     } from '../modules/samtools/faidx/main'
include { FDSTOOLS_TSSV                                      } from '../modules/fdstools/tssv/main'
include { UMIEC_FASTQTOBAM as FASTQTOBAM                     } from '../modules/umiec/fastqtobam/main'
include { UMIERRORCORRECT_PREPROCESSING as EXTRACTUMIS       } from '../modules/umierrorcorrect/preprocessing/main'
include { UMIERRORCORRECT_UMIERRORCORRECT as UMIERRORCORRECT } from '../modules/umierrorcorrect/umierrorcorrect/main'
include { UMIERRORCORRECT_FILTERBAM as FILTERBAM             } from '../modules/umierrorcorrect/filterbam/main'

workflow UMIEC_CONSENSUS {

    take:
    reads
    bed_file
    library_file
    fasta

    main:
    ch_versions = channel.empty()

    SAMTOOLS_FAIDX(fasta)

    // Preprocessing for UMI error correction
    EXTRACTUMIS(reads, params.umi_length, params.spacer_length)

    // Map preprocessed reads to STR markers
    FDSTOOLS_TSSV(EXTRACTUMIS.out.umi_fastq, library_file, params.indel_score, params.mismatches)
    ch_versions = ch_versions.mix(FDSTOOLS_TSSV.out.versions)

    // Convert fastq to bam (alignment free)
    FASTQTOBAM(FDSTOOLS_TSSV.out.tssv_out, bed_file, library_file)

    // Run UMIErrorCorrect
    UMIERRORCORRECT(FASTQTOBAM.out.bam, FASTQTOBAM.out.bai, bed_file, fasta, SAMTOOLS_FAIDX.out.fai, params.consensus_method)

    // Remove reads with less than min_reads support
    FILTERBAM(UMIERRORCORRECT.out.cons_bam, UMIERRORCORRECT.out.cons_bai, params.call_min_reads)
    
    emit:
    filtered_bam = FILTERBAM.out.filtered_bam
    cons_bam     = UMIERRORCORRECT.out.cons_bam
    cons_bai     = UMIERRORCORRECT.out.cons_bai
    cons_file    = UMIERRORCORRECT.out.cons_tsv

    versions     = ch_versions
}