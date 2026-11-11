process FDSTOOLS_TSSV {
    tag "$meta.id"
    label 'process_single'

    container 'quay.io/sfilges/fdstools:2.1.1'

    // Publish the per-marker read folder, the sequence count table and the per-marker statistics.
    // ("tssv_out/*" matched nothing: '*' does not cross '/', and the folder itself is the output.)
    publishDir { "${params.outdir}/${workflow.runName}/fdstools/pre_umi/${meta.id}/" }, mode: params.publish_dir_mode, pattern: "{tssv_out,*_tssv.csv,*_tssv_stats.tsv}"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(library_file)
    val indel_score
    val mismatches

    output:
    tuple val(meta), path("tssv_out")                  , emit: tssv_out
    tuple val(meta), path("tssv_out/*/paired.fq.gz")   , emit: paired_fq
    tuple val(meta), path("*_tssv.csv")                , emit: csv     // read count per unique sequence per marker
    tuple val(meta), path("*_tssv_stats.tsv")          , emit: stats   // per-marker paired/left-only/right-only counts
    path "versions.yml"                                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    fdstools tssv \\
        --num-threads $task.cpus \\
        --dir tssv_out \\
        --indel-score $indel_score \\
        --mismatches $mismatches \\
        --minimum 2 \\
        --report ${prefix}_tssv_stats.tsv \\
        ${args} \\
        $library_file \\
        $reads \\
        ${prefix}_tssv.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tssv: \$(fdstools tssv -v | awk '{print \$2}')
        fdstools: \$(fdstools tssv -v | sed -n 's/.*(part of fdstools \\(.*\\))/\\1/p')
    END_VERSIONS
    """
}
