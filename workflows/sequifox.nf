
include { samplesheetToList         } from 'plugin/nf-schema'
include { validateParameters        } from 'plugin/nf-schema'

//include { ADAPTERREMOVAL        } from "./modules/adapterremoval/main"
//include { FLASH                 } from "./modules/flash/main"
//include { FDSTOOLS_PIPELINE     } from "./modules/fdstools/pipeline/main"
//include { FDSTOOLS_TSSV         } from "./modules/fdstools/tssv/main"
//include { FDSTOOLS_STUTTERMARK  } from "./modules/fdstools/stuttermark/main"
//include { FASTQTOBAM            } from "./modules/fastqtobam/main"
//include { UMIERRORCORRECT       } from "./modules/umierrorcorrect/main"


workflow SEQUIFOX {

    take:
    samplesheet
    //library_file
    //marker_bed
    //ini_file
    //genome
    //outdir

    main:

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
    Channel.fromList(samplesheetToList(samplesheet, "assets/schema_input.json"))
        // Uses a map transformation to iterate over each row in the samplesheet.
        .map {meta, fastq_1, fastq_2 -> 
            // structure the output depending on the input
            if(fastq_2) {
                [meta, [fastq_1, fastq_2]]
            } else if (fastq_1) {
                [meta, [fastq_1]]
            } 
        }
        .set { ch_fastqs }
    
    ch_fastqs.view()

    // Remove adapters
    //ADAPTERREMOVAL(ch_fastqs)

    // If paired ends, combine reads into single reads using FLASH
    //FLASH(ADAPTERREMOVAL.out.fastqs)


    // Preprocessing


    // Alignment of reads to markers by TSSV
    //FDSTOOLS_TSSV(PREPROCESSING.out.fastq, library_file, params.indel_score, params.mismatches)

    // Convert to BAM
    //FASTQTOBAM(FDSTOOLS_TSSV.out.aligned)


    // UMIErrorCorrect
    //UMIERRORCORRECT(FASTQTOBAM.out.bam)

    //



    emit:

}