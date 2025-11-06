process ADAPTERREMOVAL {
    tag "$meta.id"

    container 'quay.io/biocontainers/adapterremoval:2.3.4--pl5321haf24da9_1'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: fastq
    path "versions.yml"             , emit: versions

    script:
    def fq1 = "${reads[0]}"
    def fq2 = "${reads[1]}"
    def adapter1 = 'AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT'
    def adapter2 = 'CAAGCAGAAGACGGCATACGAGATNNNNNNGTGACTGGAGTTCAGACGTGTGCTCTTCCG'
    def args = task.ext.args ?: ''
    """
    AdapterRemoval \\
        --file1 $fq1 \\
        --file2 $fq2 \\
        --adapter1 $adapter1 \\
        --adapter2 $adapter2 \\
        --threads $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        adapterremoval: \$(adapterremoval --version | sed 's/.*ver\\. //')
    END_VERSIONS
    """
}