process FDSTOOLS_STUTTERMARK {
    tag "$meta.id"
    label 'process_single'

    container ''

    input:
    tuple val(meta), path(infile)
    path library_file

    output:
    tuple val(meta), path(outfile), emit: stuttermark

    script:
    """
    outfile=${meta.id}_stutter.csv
    
    fdstools stuttermark \\
        -i $infile \\
        -o $outfile \\
        -l $libraryfile
    """
}