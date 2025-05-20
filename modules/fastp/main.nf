process FASTP {
    tag "$meta.id with $task.cpus cores"
    label 'process_medium'

    cpus 4

    container 'quay.io/biocontainers/fastp:0.23.4--hadf994f_2'

    publishDir = [
        [
            path: {"${params.outdir}/${workflow.runName}/reports/fastp/${meta.id}"},
            mode: params.publish_dir_mode,
            pattern: "*.{html,json,log}"
        ],
        [
            path: {"${params.outdir}/${workflow.runName}/preprocessing/fastp/${meta.id}"},
            mode: params.publish_dir_mode,
            pattern: '*.fastq.gz'
        ]
    ]

    input:
    tuple val(meta), path(reads)
    val save_merged
    val umi_length
    val spacer_length
    val min_read_length

    output:
    tuple val(meta), path('*_fastp.fastq.gz')   , emit: reads
    tuple val(meta), path('*.json')             , emit: json
    tuple val(meta), path('*.html')             , emit: html
    tuple val(meta), path('*.log')              , emit: log
    path "versions.yml"                         , emit: versions
    tuple val(meta), path('*_merged.fastq.gz'), optional:true, emit: reads_merged

    script:
    def prefix = "${meta.id}"
    def merge_fastq = save_merged ? "-m --merged_out ${prefix}_merged.fastq.gz" : '' 
    """
    [ ! -f ${prefix}_1.fastq.gz ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz
    [ ! -f ${prefix}_2.fastq.gz ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz
    fastp \\
        --in1 ${prefix}_1.fastq.gz \\
        --in2 ${prefix}_2.fastq.gz \\
        --out1 ${prefix}_1_fastp.fastq.gz \\
        --out2 ${prefix}_2_fastp.fastq.gz \\
        --json ${prefix}.fastp.json \\
        --html ${prefix}.fastp.html \\
        --correction \\
        $merge_fastq \\
        -l $min_read_length \\
        --thread $task.cpus \\
        --detect_adapter_for_pe \\
        $args \\
        2> >(tee ${prefix}.fastp.log >&2)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """
}