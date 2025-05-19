process PICARD_FASTQTOSAM {
    tag "$meta.id"
    
    //https://gatk.broadinstitute.org/hc/en-us/articles/360036351132-FastqToSam-Picard
    container 'biocontainers/picard:3.1.1--hdfd78af_0'

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/preprocessing/unaligned_bam/${meta.id}"},
        mode: params.publish_dir_mode,
        pattern: "*.bam"
    ]

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(".bam"), emit: bam

    script:
    def f1 = ${reads}[0]
    """
    java -jar picard.jar FastqToSam \\
        F1=$f1 \\
        O=${meta.id}.bam \\
        SM=${meta.id}
    """
}