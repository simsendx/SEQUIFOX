//
// FGBIO UMI CONSENSUS FORMATION
//

// fgbio
include { FGBIO_FASTQTOBAM                                 } from './modules/fgbio/fastqtobam/main'
include { ALIGN_BAM as ALIGN_RAW_BAM                       } from './modules/fgbio/alignbam/main'
include { FGBIO_GROUPREADSBYUMI                            } from './modules/fgbio/groupreadsbyumi/main'
include { FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS       } from './modules/fgbio/callandfiltermolecularconsensusreads/main'


workflow FGBIO_CONSENSUS {

    take:
    reads
    read_structures
    fasta
    fai
    dict
    bwa

    // Convert preprocessed fastq to bam
    FGBIO_FASTQTOBAM(ch_reads, params.read_structures)

    // align
    ALIGN_RAW_BAM(FGBIO_FASTQTOBAM.out.bam, ch_fasta, PREPARE_GENOME.out.fasta_fai, PREPARE_GENOME.out.dict, PREPARE_GENOME.out.bwa, "template-coordinate")

    FGBIO_GROUPREADSBYUMI(ALIGN_RAW_BAM.out.bam, params.groupreadsbyumi_strategy, params.groupreadsbyumi_edits)

    // Run fgbio CallMolecularConsensusReads and fgbio FilterConsensusReads in the same process
    // for greater efficiency. Uses the same min_reads value for constructing and filtering consensus 
    // reads
    FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS(FGBIO_GROUPREADSBYUMI.out.bam, ch_fasta, PREPARE_GENOME.out.fasta_fai, params.call_min_reads, params.call_min_baseq, params.filter_max_base_error_rate)

    emit:
    consensus_reads = FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS.out.bam

}