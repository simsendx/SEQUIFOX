process UMIERRORCORRECT_FILTERBAM {
    tag "$meta.id"

    publishDir "${params.outdir}/${workflow.runName}/out/${meta.id}", mode: params.publish_dir_mode, pattern: "*_filtered.bam"

    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(bai)
    val consensus_cutoff

    output:
    tuple val(meta), path("*_filtered.bam"), emit: filtered_bam

    script:
    """
    filter_bam.py \\
        -i $bam \\
        -o ${meta.id}_filtered.bam \\
        -c $consensus_cutoff
    """
}