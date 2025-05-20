process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_single'

    container 'quay.io/biocontainers/samtools:1.21--h50ea8bc_0'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path ("*.{fa,fasta}") , emit: fa , optional: true
    tuple val(meta), path ("*.fai")        , emit: fai, optional: true
    tuple val(meta), path ("*.gzi")        , emit: gzi, optional: true
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    samtools \\
        faidx \\
        --threads ${task.cpus} \\
        $fasta \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}