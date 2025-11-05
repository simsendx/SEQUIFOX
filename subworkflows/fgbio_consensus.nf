//
// FGBIO UMI CONSENSUS FORMATION
//

// fgbio
include { FDSTOOLS_TSSV                                    } from '../modules/fdstools/tssv/main'
include { FGBIO_FASTQTOBAM                                 } from '../modules/fgbio/fastqtobam/main'
include { ALIGN_BAM as ALIGN_RAW_BAM                       } from '../modules/fgbio/alignbam/main'
include { FGBIO_GROUPREADSBYUMI                            } from '../modules/fgbio/groupreadsbyumi/main'
include { FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS       } from '../modules/fgbio/callandfiltermolecularconsensusreads/main'


workflow FGBIO_CONSENSUS {

    take:
    reads
    fasta
    fai
    dict
    bwa
    library_file

    main:

    FDSTOOLS_TSSV(reads, library_file, params.indel_score, params.mismatches)

    // Convert preprocessed fastq to bam
    FGBIO_FASTQTOBAM(reads, params.read_structures)

    // align
    ALIGN_RAW_BAM(FGBIO_FASTQTOBAM.out.bam, fasta, fai, dict, bwa, "template-coordinate")

    // group by UMIs
    FGBIO_GROUPREADSBYUMI(
        ALIGN_RAW_BAM.out.bam,
        params.groupreadsbyumi_strategy,
        params.groupreadsbyumi_edits,
        params.min_mapping_quality,
        params.include_non_pf_reads
    )

    // Run fgbio CallMolecularConsensusReads and fgbio FilterConsensusReads in the same process
    // for greater efficiency. Uses the same min_reads value for constructing and filtering consensus 
    // reads
    FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS(FGBIO_GROUPREADSBYUMI.out.bam, fasta, fai, params.call_min_reads, params.call_min_baseq, params.filter_max_base_error_rate)

    emit:
    consensus_bam = FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS.out.bam

}