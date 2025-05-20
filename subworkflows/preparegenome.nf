//
// PREPARE GENOME
//

include { BWA_INDEX                  } from '../modules/bwa/index/main'
include { SAMTOOLS_FAIDX             } from '../modules/samtools/faidx/main'
include { SAMTOOLS_DICT              } from '../modules/samtools/dict/main'

workflow PREPARE_GENOME {
    take:
    fasta // channel: [mandatory] fasta

    main:
    versions = Channel.empty()

    BWA_INDEX(fasta)
    // If aligner is bwa-mem
    SAMTOOLS_FAIDX(fasta)
    SAMTOOLS_DICT(fasta)

    // Gather versions of all tools used
    versions = versions.mix(BWA_INDEX.out.versions)
    versions = versions.mix(SAMTOOLS_FAIDX.out.versions)

    emit:
    bwa = BWA_INDEX.out.index.collect()          // path: bwa/*
    dict = SAMTOOLS_DICT.out.dict.collect()      // path: genome.fasta.dict
    fasta_fai = SAMTOOLS_FAIDX.out.fai.collect() // path: genome.fasta.fai
    versions                                     // channel: [ versions.yml ]
}