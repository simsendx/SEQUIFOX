process BWA_INDEX {
    tag "$fasta"
    label 'process_single'

    container 'quay.io/biocontainers/bwa:0.7.18--he4a0461_0'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("bwa")    , emit: index
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${fasta.baseName}"
    def args   = task.ext.args ?: ''
    """
    mkdir bwa
    bwa \\
        index \\
        $args \\
        -p bwa/${prefix} \\
        $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(echo \$(bwa 2>&1) | sed 's/^.*Version: //; s/Contact:.*\$//')
    END_VERSIONS
    """
}