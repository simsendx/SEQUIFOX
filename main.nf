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
include { samplesheetToList           } from 'plugin/nf-schema'
include { validateParameters          } from 'plugin/nf-schema'

// Workflows and subworkflows
include { PREPARE_GENOME              } from './subworkflows/preparegenome'
include { FGBIO_CONSENSUS             } from './subworkflows/fgbio_consensus'
include { FDSTOOLS                    } from './subworkflows/fdstools'

// Preprocessing
include { FASTQC                      } from './modules/fastqc/main'
include { FASTQC as FASTQCFASTP       } from './modules/fastqc/main'
include { FASTP                       } from './modules/fastp/main'

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
    // file stream into a value channel so that it can be reused for all samples
    ch_library_file = params.library_file ? Channel.fromPath(params.library_file, checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect() : 
        Channel.fromPath("${projectDir}/assets/simsen_library.txt", checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect()

    ch_bed_file = params.bed_file ? Channel.fromPath(params.bed_file, checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect() : 
        Channel.fromPath("${projectDir}/assets/simsen_str_markers.bed", checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect()

    ch_ini_file = params.ini_file ? Channel.fromPath(params.ini_file, checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect() : 
        Channel.fromPath("${projectDir}/assets/simsen.ini", checkIfExists: true).map { it -> [[id: it.baseName], it] }.collect()

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

    FASTQCFASTP(ch_reads)

    FGBIO_CONSENSUS(ch_reads, params.read_structures, ch_fasta, PREPARE_GENOME.out.fasta_fai, PREPARE_GENOME.out.dict, PREPARE_GENOME.out.bwa)

    FDSTOOLS(ch_reads, FGBIO_CONSENSUS.out.consensus_bam, ch_library_file, ch_ini_file)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/