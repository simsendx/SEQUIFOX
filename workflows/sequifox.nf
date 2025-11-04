/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Nextflow
include { softwareVersionsToYAML      } from '../subworkflows/utils'

// Workflows and subworkflows
include { PREPARE_GENOME              } from '../subworkflows/preparegenome'
include { UMIEC_CONSENSUS             } from '../subworkflows/umiec_consensus'
include { FGBIO_CONSENSUS             } from '../subworkflows/fgbio_consensus'
include { FDSTOOLS                    } from '../subworkflows/fdstools'

// Modules
include { FASTQC as FASTQC_RAW        } from '../modules/fastqc/main'
include { FASTQC as FASTQC_MERGED     } from '../modules/fastqc/main'
include { FASTP                       } from '../modules/fastp/main'
include { MULTIQC                     } from '../modules/multiqc/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SEQUIFOX WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SEQUIFOX {

    take:
    ch_fastqs
    ch_library_file
    ch_ini_file
    ch_bed_file
    ch_fasta

    main:
    
    // Initilialise versions and reports channels
    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    //
    // FASTQC on raw reads
    //
    FASTQC_RAW(ch_fastqs)
    ch_versions = ch_versions.mix(FASTQC_RAW.out.versions)

    //ch_fastqc_raw_html = FASTQC_RAW.out.html
    ch_fastqc_raw_zip  = FASTQC_RAW.out.zip

    // Preprocessing with fastp:
    // - remove adapters and poly_g (2-color chemistry runs only)
    // - merge reads (if selected) and error correct
    // - perform basic quality filtering (read length, quality score)
    FASTP(
        ch_fastqs,
        params.fastp_save_merged,
        params.umi_length, 
        params.spacer_length,
        params.min_read_length, 
        params.correction,
        params.overlap_len_require, 
        params.overlap_diff_limit, 
        params.overlap_diff_percent_limit
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)

    // If reads are merged, use the merged fastqs downstream (FASTP.out.reads_merged). In FASTP, 
    // if merging reads, the --out1 and --out2 files will be the unmerged reads only! If not merging, 
    // use the  processed --out1 and --out2 read files (FASTP.out.reads)
    if(params.fastp_save_merged){
        ch_reads = FASTP.out.reads_merged
    } else {
        ch_reads = FASTP.out.reads
    }
    //ch_reads.view()

    //
    // FASTQC on pre-processed/filtered reads
    //
    FASTQC_MERGED(ch_reads)

    // Output file channels and collect for multiqc
    ch_trim_json        = FASTP.out.json
    //ch_fastqc_trim_html = FASTQC_MERGED.out.html
    ch_fastqc_trim_zip  = FASTQC_MERGED.out.zip

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_fastqc_raw_zip.collect{it[1]}.ifEmpty([])
    )

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_trim_json.collect{it[1]}.ifEmpty([])
    )

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_fastqc_trim_zip.collect{it[1]}.ifEmpty([])
    )

    //
    // Run main analysis workflows
    //
    if(params.mode == 'fgbio') {
        // Prepare genome files (faidx index, samtools dict and bwa index)
        PREPARE_GENOME(ch_fasta)
        FGBIO_CONSENSUS(ch_reads, ch_fasta, PREPARE_GENOME.out.fasta_fai, PREPARE_GENOME.out.dict, PREPARE_GENOME.out.bwa, ch_library_file)
        ch_consensus_bam = FGBIO_CONSENSUS.out.consensus_bam
    } else {
        UMIEC_CONSENSUS(ch_reads, ch_bed_file, ch_library_file, ch_fasta)
        ch_consensus_bam = UMIEC_CONSENSUS.out.filtered_bam
    }

    //
    // Run fdstools
    //
    FDSTOOLS(ch_consensus_bam, ch_library_file, ch_ini_file)
    ch_versions = ch_versions.mix(FDSTOOLS.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/${workflow.runName}/pipeline_info", name: 'versions.yml', sort: true, newLine: true)

    //
    // Multiqc
    //
    MULTIQC (
        ch_multiqc_files.collect()
    )
}