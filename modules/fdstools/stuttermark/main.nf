process FDSTOOLS_STUTTERMARK {
    tag "$meta.id"
    label 'process_single'

    container 'quay.io/sfilges/fdstools:2.1.1'

    publishDir "${params.outdir}/${workflow.runName}/fdstools/post_umi/${meta.id}", mode: params.publish_dir_mode, pattern: "*_stutter.csv"

    input:
    tuple val(meta), path(infile)
    tuple val(meta2), path(library_file)

    output:
    tuple val(meta), path("*_stutter.csv")   , emit: stuttermark
    path "versions.yml"                      , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    fdstools stuttermark \\
        $args \\
        -i $infile \\
        -o ${meta.id}_stutter.csv \\
        -l $library_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tssv: \$(fdstools stuttermark -v | awk '{print \$2}')
        fdstools: \$(fdstools stuttermark -v | sed -n 's/.*(part of fdstools \\(.*\\))/\\1/p')
    END_VERSIONS
    """
}