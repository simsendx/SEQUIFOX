#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    simsendx/sequifox
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/simsendx/SEQUIFOX
----------------------------------------------------------------------------------------
*/

// Enable dsl 2
nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Nextflow
include { samplesheetToList                                  } from 'plugin/nf-schema'
include { validateParameters                                 } from 'plugin/nf-schema'

// Workflows and subworkflows
include { PREPARE_GENOME              } from './subworkflows/preparegenome'
include { FGBIO_CONSENSUS             } from './subworkflows/fgbio_consensus'
//include { SEQUIFOX                  } from './workflows/sequifox'

// Preprocessing
include { FASTQC                                           } from './modules/fastqc/main'
include { FASTQC as FASTQCFASTP                            } from './modules/fastqc/main'
include { FASTP                                            } from './modules/fastp/main'


// samtools
include { SAMTOOLS_FAIDX                                   } from './modules/samtools/faidx/main'
include { SAMTOOLS_BAMTOFQ                                 } from './modules/samtools/bamtofq/main'

// fgbio
include { FGBIO_FASTQTOBAM                                 } from './modules/fgbio/fastqtobam/main'
include { ALIGN_BAM as ALIGN_RAW_BAM                       } from './modules/fgbio/alignbam/main'
include { FGBIO_GROUPREADSBYUMI                            } from './modules/fgbio/groupreadsbyumi/main'
include { FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS       } from './modules/fgbio/callandfiltermolecularconsensusreads/main'

// Main analysis
include { FDSTOOLS_TSSV                                    } from './modules/fdstools/tssv/main'
include { FDSTOOLS_PIPELINE                                } from './modules/fdstools/pipeline/main'
include { FDSTOOLS_STUTTERMARK                             } from './modules/fdstools/stuttermark/main'


//include { SAMTOOLS_REHEADER                                } from './modules/samtools/reheader/main'
//include { UMIERRORCORRECT_PREPROCESSING as PREPROCESSING   } from './modules/umierrorcorrect/preprocessing/main'
//include { PICARD_FASTQTOSAM as PICARD_FASTQTOBAM           } from './modules/picard/fastqtosam/main'
//include { UMIERRORCORRECT_UMIERRORCORRECT as UMIERRORCORRECT } from './modules/umierrorcorrect/umierrorcorrect/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow {

    if(params.validate_params){
        // Validate parameters relative to the parameter JSON schema 
        // in default location: "nextflow_schema.json"
        validateParameters()
    }

    // Initilialise versions and reports channels
    ch_versions = Channel.empty()
    ch_reports  = Channel.empty()
    ch_trim_reads = Channel.empty()
    ch_multiqc_files = Channel.empty()

    // Getting user supplied files or else use build-in files (works for Simsen workflow only)
    ch_library_file = params.library_file ? Channel.fromPath(params.library_file, checkIfExists: true) : 
        Channel.fromPath("${projectDir}/assets/simsen_library.txt", checkIfExists: true)

    ch_bed_file = params.bed_file ? Channel.fromPath(params.bed_file, checkIfExists: true) : 
        Channel.fromPath("${projectDir}/assets/simsen_str_markers.bed", checkIfExists: true)

    ch_ini_file = params.ini_file ? Channel.fromPath(params.ini_file, checkIfExists: true) : 
        Channel.fromPath("${projectDir}/assets/simsen.ini", checkIfExists: true)

    ch_fasta = params.fasta ? Channel.fromPath(params.fasta, checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect() : 
        Channel.fromPath("${projectDir}/assets/mini_hg38.fa", checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect()

    // Prepare genome files (faidx index, samtools dict and bwa index)
    PREPARE_GENOME(ch_fasta)

    // Import samplesheet
    // It is the order of fields in the samplesheet JSON schema which defines 
    // the order of items in the channel, *not* the order of fields in the 
    // samplesheet file.
    ch_fastqs = Channel.fromList(samplesheetToList(params.samplesheet, "assets/schema_input.json"))
        // Uses a map transformation to iterate over each row in the samplesheet.
        .map {meta, fastq_1, fastq_2 -> 
            // structure the output depending on the input
            if(fastq_2) {
                [meta, [fastq_1, fastq_2]]
            } else if (fastq_1) {
                [meta, [fastq_1]]
            } 
        }
    //ch_fastqs.view()

    FASTQC(ch_fastqs)

    // Preprocessing with fastp:
    // - remove adapters and poly_g (2-color chemistry runs only)
    // - merge reads (if selected) and error correct
    // - perform basic quality filtering (read length, quality score)
    // - 
    FASTP(ch_fastqs, params.fastp_save_merged, params.umi_length, params.spacer_length, params.min_read_length)

    // If reads are merged, use the merged fastqs downstream (FASTP.out.reads_merged). In FASTP, 
    // if merging reads, the --out1 and --out2 files will be the unmerged reads only! If not merging, 
    // use the  processed --out1 and --out2 read files (FASTP.out.reads)
    if(params.fastp_save_merged){
        ch_reads = FASTP.out.reads_merged
    } else {
        ch_reads = FASTP.out.reads
    }
    //ch_reads.view()

    //FASTQCFASTP(ch_reads)

    // Pre UMI statistics
    FDSTOOLS_TSSV(ch_reads, ch_library_file, params.indel_score, params.mismatches)

    // Preprocessing for UMI error correction
    //PREPROCESSING(ch_reads, params.umi_length, params.spacer_length)

    // Convert fastq to bam (alignment free)
    //PICARD_FASTQTOBAM(ch_reads)

    // REHEADER
    //SAMTOOLS_REHEADER(PICARD_FASTQTOBAM.out.bam, "CHR12", 10)

    // Run UMIErrorCorrect
    //UMIERRORCORRECT(SAMTOOLS_REHEADER.out.bam, params.bed_file, params.ref_genome, params.consensus_method)

    // FGBIO
    //FGBIO_FASTQTOBAM(ch_reads, params.read_structures)

    //ALIGN_RAW_BAM(FGBIO_FASTQTOBAM.out.bam, ch_fasta, PREPARE_GENOME.out.fasta_fai, PREPARE_GENOME.out.dict, PREPARE_GENOME.out.bwa, "template-coordinate")

    //FGBIO_GROUPREADSBYUMI(ALIGN_RAW_BAM.out.bam, params.groupreadsbyumi_strategy, params.groupreadsbyumi_edits)

    // Run fgbio CallMolecularConsensusReads and fgbio FilterConsensusReads in the same process
    // for greater efficiency. Uses the same min_reads value for constructing and filtering consensus 
    // reads
    //FGBIO_CALLANDFILTERMOLECULARCONSENSUSREADS(FGBIO_GROUPREADSBYUMI.out.bam, ch_fasta, PREPARE_GENOME.out.fasta_fai, params.call_min_reads, params.call_min_baseq, params.filter_max_base_error_rate)

    FGBIO_CONSENSUS(ch_reads, params.read_structures, ch_fasta, PREPARE_GENOME.out.fasta_fai, PREPARE_GENOME.out.dict, PREPARE_GENOME.out.bwa)

    SAMTOOLS_BAMTOFQ(FGBIO_CONSENSUS.out.consensus_bam)

    FDSTOOLS_PIPELINE(SAMTOOLS_BAMTOFQ.out.fastq, ch_ini_file, ch_library_file)

    FDSTOOLS_STUTTERMARK(FDSTOOLS_PIPELINE.out.csv, ch_library_file)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/