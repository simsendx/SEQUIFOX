process FGBIO_FASTQTOBAM {
    tag "$meta.id"

    //conda "bioconda::fgbio=2.4.0"
    container 'community.wave.seqera.io/library/fgbio:2.4.0--913bad9d47ff8ddc'

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/preprocessing/fgbio/${meta.id}"},
            mode: params.publish_dir_mode,
            pattern: "*.bam"
    ]

    input:
    tuple val(meta), path(reads)
    val read_structures

    output:
    tuple val(meta), path('*.bam'), emit: bam
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mem_gb = 1
    """
    fgbio \\
        -Xmx${mem_gb}g \\
        --tmp-dir=. \\
        --async-io=true \\
        --compression=1 \\
        FastqToBam \\
        --input $reads \\
        --read-structures $read_structures \\
        --sample $meta.id \\
        --library $meta.id \\
        --output ${meta.id}.bam \\
        ${args}

     cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fgbio: \$( echo \$(fgbio --version 2>&1 | tr -d '[:cntrl:]' ) | sed -e 's/^.*Version: //;s/\\[.*\$//')
    END_VERSIONS
    """
}