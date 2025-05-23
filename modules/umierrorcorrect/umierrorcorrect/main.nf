process UMIERRORCORRECT_UMIERRORCORRECT {
    tag "$meta.id"
    label 'process_low'

    container 'quay.io/sfilges/umierrorcorrect:v0.31'

    publishDir "${params.outdir}/${workflow.runName}/umierrorcorrect/${meta.id}", mode: params.publish_dir_mode, pattern: "*"

    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(bai)
    tuple val(meta3), path(bed_file)
    tuple val(meta4), path(fasta)
    tuple val(meta5), path(fai)
    val consensus_method

    output:
    tuple val(meta), path("*_cons.tsv"), emit: cons_tsv
    tuple val(meta), path("*_consensus_reads.bam"), emit: cons_bam
    tuple val(meta), path("*_consensus_reads.bam.bai"), emit: cons_bai
    tuple val(meta), path("*.hist"), emit: hist

    script:
    """
    umi_error_correct.py \\
        -o . \\
        -b $bam \\
        -bed $bed_file \\
        -r $fasta \\
        -c $consensus_method \\
        -s ${meta.id} \\
        -t $task.cpus
    """
}