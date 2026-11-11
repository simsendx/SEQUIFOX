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
    versions = channel.empty()

    // Use user-provided bwa index or generate fresh index
    // Shape must match BWA_INDEX.out.index: [ meta, directory containing *.amb/.ann/.bwt/.pac/.sa ]
    if(params.bwa_index){
        def index_dir = file(params.bwa_index, checkIfExists: true)
        if (!index_dir.isDirectory() || !index_dir.listFiles().any { f -> f.name.endsWith('.amb') }) {
            error "--bwa_index must be a directory containing a BWA index (*.amb, *.ann, *.bwt, *.pac, *.sa): ${params.bwa_index}"
        }
        log.info "Using custom BWA index: ${index_dir}"
        ch_index = channel.value([ [id: index_dir.name], index_dir ])
    } else {
        BWA_INDEX(fasta)
        ch_index = BWA_INDEX.out.index.collect()
        versions = versions.mix(BWA_INDEX.out.versions)
    }

    // If aligner is bwa-mem
    SAMTOOLS_FAIDX(fasta)
    SAMTOOLS_DICT(fasta)

    // Gather versions of all tools used
    versions = versions.mix(SAMTOOLS_FAIDX.out.versions)
    versions = versions.mix(SAMTOOLS_DICT.out.versions)

    emit:
    bwa = ch_index                               // [ meta, path: bwa index dir ]
    dict = SAMTOOLS_DICT.out.dict.collect()      // path: genome.fasta.dict
    fasta_fai = SAMTOOLS_FAIDX.out.fai.collect() // path: genome.fasta.fai
    versions                                     // channel: [ versions.yml ]
}