process UMIERRORCORRECT_PREPROCESSING {
    tag "$meta.id"
    label 'process_low'

    container 'quay.io/sfilges/umierrorcorrect:v0.31'

    publishDir "${params.outdir}/${workflow.runName}/preprocessing/${meta.id}", mode: params.publish_dir_mode, pattern: "*_umis_in_header.fastq.gz"
    
    input:
    tuple val(meta), path(reads)
    val umi_length
    val spacer_length

    output:
    tuple val(meta), path("*_umis_in_header.fastq.gz"), emit: umi_fastq

    script:
    """
    preprocess.py \\
        -o . \\
        -r1 $reads \\
        -ul $umi_length \\
        -sl $spacer_length \\
        -s ${meta.id} \\
        -t $task.cpus
    """
}