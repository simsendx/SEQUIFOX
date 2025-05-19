process FASTQC {
    tag "$meta.id with $task.cpus cores"
    label 'process_medium'

    container 'biocontainers/fastqc:0.12.1--hdfd78af_0'

    cpus 4

    publishDir = [
            path: {"${params.outdir}/${workflow.runName}/reports/fastqc/${meta.id}"},
            mode: params.publish_dir_mode,
            pattern: "*.{html,json,log}"
    ]

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path  "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fastqc \\
        $args \\
        --threads $task.cpus \\
        $reads
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
    END_VERSIONS
    """
}