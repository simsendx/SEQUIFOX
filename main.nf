#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    simsendx/sequifox
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : 
----------------------------------------------------------------------------------------
*/

// Enable dsl 2
nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { samplesheetToList                                  } from 'plugin/nf-schema'
include { validateParameters                                 } from 'plugin/nf-schema'

include { FASTQC                                             } from './modules/fastqc/main'
include { FASTQC as FASTQCFASTP                              } from './modules/fastqc/main'
include { FASTP                                              } from './modules/fastp/main'
include { FDSTOOLS_TSSV as TSSV                              } from './modules/fdstools/tssv/main'
include { PICARD_FASTQTOSAM as FASTQTOBAM                    } from './modules/picard/fastqtosam/main'

include { UMIERRORCORRECT_UMIERRORCORRECT as UMIERRORCORRECT } from './modules/umierrorcorrect/umierrorcorrect/main'

//include { SEQUIFOX                  } from './workflows/sequifox'


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

    // It is the order of fields in the samplesheet JSON schema which defines 
    // the order of items in the channel, *not* the order of fields in the 
    // samplesheet file.
    Channel.fromList(samplesheetToList(params.samplesheet, "assets/schema_input.json"))
        // Uses a map transformation to iterate over each row in the samplesheet.
        .map {meta, fastq_1, fastq_2 -> 
            // structure the output depending on the input
            if(fastq_2) {
                [meta, [fastq_1, fastq_2]]
            } else if (fastq_1) {
                [meta, [fastq_1]]
            } 
        }
        .set {ch_fastqs}
    
    //ch_fastqs.view()

    FASTQC(ch_fastqs)
    FASTP(ch_fastqs, params.fastp_save_merged)

    // If reads are merged, use the merged fastqs downstream (FASTP.out.reads_merged). In FASTP, 
    // if merging reads, the --out1 and --out2 files will be the unmerged reads only! If not merging, 
    // use the  processed --out1 and --out2 read files (FASTP.out.reads)
    if(params.fastp_save_merged){
        ch_reads = FASTP.out.reads_merged
    } else {
        ch_reads = FASTP.out.reads
    }

    FASTQCFASTP(ch_reads)

    ch_reads.view()

    ch_library_file = channel.fromPath(params.library_file)

    ch_library_file.view()

    TSSV(ch_reads, ch_library_file, params.indel_score, params.mismatches)


    //UMIERRORCORRECT(ch_bam)

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/