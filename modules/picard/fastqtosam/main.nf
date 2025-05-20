process PICARD_FASTQTOSAM {
    tag "$meta.id"
    
    //https://gatk.broadinstitute.org/hc/en-us/articles/360036351132-FastqToSam-Picard
    container 'quay.io/biocontainers/picard:3.4.0--hdfd78af_0'

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/preprocessing/${meta.id}"},
        mode: params.publish_dir_mode,
        pattern: "*.bam"
    ]

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.bam"), emit: bam

    script:
    """
    picard \\
        -Xmx2G \\
        FastqToSam \\
        -F1 $reads \\
        -O ${meta.id}.bam \\
        -SM ${meta.id} -RG rg0013 -LB Solexa-272222
    """
}