process FLASH {
    tag "$meta.id"

    // https://github.com/Jerrythafast/FLASH-lowercase-overhang?tab=readme-ov-file
    // https://github.com/sfilges/UMIec_forensics/blob/main/umierrorcorrect_forensics/run_flash.py
    container 'quay.io/sfilges/flash:1.2.11'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path(reads)

    script:
    def fq1 = "${reads[0]}"
    def fq2 = "${reads[1]}"
    """
    flash \\
        $fq1 \\
        $fq2 \\
        -t $task.cpus \\
        -lz \\
        $args 2>&1 | tee flash.log
    """
}