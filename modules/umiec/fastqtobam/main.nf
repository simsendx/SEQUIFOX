process UMIEC_FASTQTOBAM {
    tag "$meta.id"
    label 'process_low'

    //container 'quay.io/biocontainers/pysam:0.23.0--py312h47d5410_0'
    container 'quay.io/hdc-workflows/bwa-samtools:4f00123'

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(bedfile)
    tuple val(meta3), path(library_file)

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.bai"), emit: bai


    script:
    """
    convert_fastq2bam.py -f ${reads} -o ${meta.id}.bam -b ${bedfile} -l ${library_file}
    """

}
