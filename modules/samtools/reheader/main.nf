process SAMTOOLS_REHEADER {
    tag "$meta.id"

    container 'quay.io/biocontainers/samtools:1.21--h50ea8bc_0'

    input:
    tuple val(meta), path(input_bam)
    val chrom
    val length

    output:
    tuple val(meta), path("output.bam"), emit: bam

    script:
    """
    # Extract original header
    samtools view -H ${input_bam} > header.sam

    # Append missing @SQ line
    echo -e "@SQ\\tSN:${chrom}\\tLN:${length}" >> header.sam

    # Reheader the BAM file
    samtools reheader header.sam ${input_bam} > output.bam
    """
}