//
// PREPARE GENOME
//
// Builds or reuses the reference files the consensus workflows need:
//   - FASTA index (.fai)            : both modes
//   - sequence dictionary (.dict)   : fgbio mode only
//   - BWA index                     : fgbio mode only
// Existing files are reused when given explicitly (--fasta_fai, --fasta_dict, --bwa_index)
// or, for .fai/.dict, when found next to the FASTA; otherwise they are built.
//

include { BWA_INDEX                  } from '../modules/bwa/index/main'
include { SAMTOOLS_FAIDX             } from '../modules/samtools/faidx/main'
include { SAMTOOLS_DICT              } from '../modules/samtools/dict/main'

//
// Return the explicitly given file (must exist), else the first existing candidate, else null.
//
def resolveReferenceFile(explicit_path, candidates, label) {
    if (explicit_path) {
        def f = file(explicit_path, checkIfExists: true)
        log.info "Using provided ${label}: ${f}"
        return f
    }
    def found = candidates.findResult { c ->
        try {
            def f = file(c)
            return f.exists() ? f : null
        } catch (Exception e) {
            // e.g. remote FASTA whose storage can't be listed: fall through and build the file
            return null
        }
    }
    if (found) {
        log.info "Using existing ${label} found next to the FASTA: ${found}"
    }
    return found
}

workflow PREPARE_GENOME {
    take:
    fasta // channel: [ meta, fasta ]

    main:
    versions = channel.empty()

    // Same fallback as main.nf when --fasta is not set
    def fasta_path = params.fasta ?: "${projectDir}/assets/mini_hg38.fa"
    def fasta_file = file(fasta_path)

    //
    // FASTA index: shape must match SAMTOOLS_FAIDX.out.fai -> [ meta, fai ]
    //
    def fai_file = resolveReferenceFile(params.fasta_fai, [ "${fasta_path}.fai" ], 'FASTA index')
    if (fai_file) {
        ch_fai = channel.value([ [id: fasta_file.baseName], fai_file ])
    } else {
        SAMTOOLS_FAIDX(fasta)
        ch_fai = SAMTOOLS_FAIDX.out.fai.collect()
        versions = versions.mix(SAMTOOLS_FAIDX.out.versions)
    }

    ch_dict  = channel.empty()
    ch_index = channel.empty()

    if (params.mode == 'fgbio') {
        //
        // Sequence dictionary: shape must match SAMTOOLS_DICT.out.dict -> [ meta, dict ]
        // Accept both naming conventions: genome.fa.dict (samtools) and genome.dict (Picard/GATK)
        //
        def dict_candidates = [ "${fasta_path}.dict", fasta_file.resolveSibling("${fasta_file.baseName}.dict").toString() ]
        def dict_file = resolveReferenceFile(params.fasta_dict, dict_candidates, 'sequence dictionary')
        if (dict_file) {
            ch_dict = channel.value([ [id: fasta_file.baseName], dict_file ])
        } else {
            SAMTOOLS_DICT(fasta)
            ch_dict = SAMTOOLS_DICT.out.dict.collect()
            versions = versions.mix(SAMTOOLS_DICT.out.versions)
        }

        //
        // BWA index: shape must match BWA_INDEX.out.index -> [ meta, directory containing *.amb/.ann/.bwt/.pac/.sa ]
        //
        if (params.bwa_index) {
            def index_dir = file(params.bwa_index, checkIfExists: true)
            if (!index_dir.isDirectory() || !index_dir.listFiles().any { f -> f.name.endsWith('.amb') }) {
                error "--bwa_index must be a directory containing a BWA index (*.amb, *.ann, *.bwt, *.pac, *.sa): ${params.bwa_index}"
            }
            log.info "Using provided BWA index: ${index_dir}"
            ch_index = channel.value([ [id: index_dir.name], index_dir ])
        } else {
            BWA_INDEX(fasta)
            ch_index = BWA_INDEX.out.index.collect()
            versions = versions.mix(BWA_INDEX.out.versions)
        }
    }

    emit:
    bwa       = ch_index   // [ meta, path: bwa index dir ]     (fgbio mode only)
    dict      = ch_dict    // [ meta, path: genome.dict ]        (fgbio mode only)
    fasta_fai = ch_fai     // [ meta, path: genome.fasta.fai ]
    versions               // channel: [ versions.yml ]
}
