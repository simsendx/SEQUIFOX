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

include { SEQUIFOX                    } from './workflows/sequifox'

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

    //
    // Import samplesheet
    //
    // It is the order of fields in the samplesheet JSON schema which defines 
    // the order of items in the channel, *not* the order of fields in the 
    // samplesheet file.
    ch_fastqs = Channel.fromList(samplesheetToList(params.samplesheet, "assets/schema_input.json"))
    // Uses a map transformation to iterate over each row in the samplesheet.
    .map {meta, fastq_1, fastq_2 ->
        // Add single_end field to meta
        meta.single_end = fastq_2 ? false : true
        
        // structure the output depending on the input
        if(fastq_2) {
            [meta, [fastq_1, fastq_2]]
        } else if (fastq_1) {
            [meta, [fastq_1]]
        }
    }
    //ch_fastqs.view()

    //
    // Run sequifox workflow
    //
    SEQUIFOX(
        ch_fastqs,
        ch_library_file,
        ch_ini_file,
        ch_bed_file,
        ch_fasta
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/