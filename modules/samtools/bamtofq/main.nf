process SAMTOOLS_BAMTOFQ {
    tag "$meta.id"
    label 'process_single'

    container 'quay.io/biocontainers/samtools:1.21--h50ea8bc_0'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path('*.fastq.gz'), emit: fastq
    

    script:
    """
    samtools bam2fq $bam | gzip > ${meta.id}.fastq.gz
    """
}