process FDSTOOLS_TSSV {
    tag "$meta.id"
    label 'process_single'

    container 'quay.io/sfilges/fdstools:2.1.1'

    publishDir "${params.outdir}/${workflow.runName}/fdstools/pre_umi/${meta.id}/", mode: params.publish_dir_mode, pattern: "tssv_out/*"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(library_file)
    val indel_score
    val mismatches

    output:
    tuple val(meta), path("tssv_out")   , emit: tssv_out
    tuple val(meta), path("tssv_out/*/paired.fq.gz")   , emit: paired_fq
    path "versions.yml"                                , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    fdstools tssv \\
        --num-threads $task.cpus \\
        --dir tssv_out \\
        --indel-score $indel_score \\
        --mismatches $mismatches \\
        --minimum 2 \\
        --report preumi.html \\
        $library_file \\
        $reads \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tssv: \$(fdstools tssv -v | awk '{print \$2}')
        fdstools: \$(fdstools tssv -v | sed -n 's/.*(part of fdstools \\(.*\\))/\\1/p')
    END_VERSIONS
    """
}