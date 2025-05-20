process FGBIO_CALLMOLECULARCONSENSUSREADS {
    tag "${meta.id}"
    label 'process_low'

    //conda "bioconda::fgbio=2.4.0"
    container 'community.wave.seqera.io/library/fgbio:2.4.0--913bad9d47ff8ddc'

    input:
    tuple val(meta), path(grouped_bam)
    val min_reads
    val min_baseq

    output:
    tuple val(meta), path("*.cons.unmapped.bam"), emit: cons_bam
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mem_gb = 8
    if (!task.memory) {
        log.info('[fgbio CallMolecularConsensusReads] Available memory not known - defaulting to 8GB. Specify process memory requirements to change this.')
    }
    else {
        mem_gb = task.memory.giga
    }

    """
    fgbio \\
        -Xmx${mem_gb}g \\
        --tmp-dir=. \\
        --async-io=true \\
        --compression=1 \\
        CallMolecularConsensusReads \\
        --input ${grouped_bam} \\
        --output ${prefix}.cons.unmapped.bam \\
        --min-reads ${min_reads} \\
        --min-input-base-quality ${min_baseq} \\
        --threads ${task.cpus} \\
        ${args};

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fgbio: \$( echo \$(fgbio --version 2>&1 | tr -d '[:cntrl:]' ) | sed -e 's/^.*Version: //;s/\\[.*\$//')
    END_VERSIONS
    """
}