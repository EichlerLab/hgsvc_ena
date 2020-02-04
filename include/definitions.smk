"""
Pipeline definitions.
"""

# Webin account name ("Webin-..."). Password is read from "password.txt" (set permissions to 400).
WEBIN_ID = 'Webin-54905'

WEBIN_JAR = '/net/eichler/vol27/projects/hgsvc/nobackups/ena/tools/webin-cli-2.1.0.jar'

# CCS directory pattern
DIR_PATTERN = {
    'hifi': '/net/eichler/vol27/projects/hgsvc/nobackups/data/sequencing/HiFi/{Sample}/ccs/data/{Run}/{CellLong}',
    'clr': '/net/eichler/vol27/projects/hgsvc/nobackups/data/sequencing/CLR/{Sample}/subread/data/{Run}/{CellLong}'
}

# ENA submission constants
ENA_STUDY = 'PRJEB36100'

ENA_LIBRARY_STRATEGY = 'WGS'
ENA_LIBRARY_SOURCE = 'GENOMIC'
ENA_LIBRARY_SELECTION = 'RANDOM'
ENA_PLATFORM = 'PACBIO_SMRT'
ENA_INSTRUMENT = 'Sequel II'

# Center aliases (for submission fields)
CENTER_NAME = {
    'UW': 'UNIVERSITY OF WASHINGTON - GENOME SCIENCES'
}

# Centerc alias
CENTER_NAME_PRETTY = {
    'UW': 'University of Washington Genome Sciences'
}

# Protocol aliases (spreadsheet field to value in XMLs)
PROTOCOL_NAME = {
    'hifi': 'HiFi',
    'clr': 'CLR'
}

UPLOAD_FILE_NAME_FORMAT_BAM = 'programatic/{Sample}/{Protocol}/{Sample}-{Protocol}-{Run}-{Cell}.bam'

DESIGN_DESCRIPTION = {
    'hifi': 'PacBio HiFi sequencing contributed by {center} for sample {sample} as part of the Human Genome Structural Variant Consortium (HGSVC)',
    'clr': 'PacBio CLR sequencing contributed by {center} for sample {sample} as part of the Human Genome Structural Variant Consortium (HGSVC)'
}

#
# Function declarations
#

def get_sample_table(protocol, sample=None):
    """
    Read a sample table for a protocol.

    :param protocol: "clr" or "hifi".
    """

    # Get sheet name
    if protocol == 'hifi':
        sheet_name = 'HiFi'
    elif protocol == 'clr':
        sheet_name = 'CLR'
    else:
        raise RuntimeError('Unknown protocol: ' + protocol)

    # Read
    df = pd.read_excel('SampleTable.xlsx', sheet_name=sheet_name)

    df = df.loc[df['Protocol'] == protocol]

    # Subset
    if sample is not None:
        df = df.loc[df['Sample'] == sample]

    # Check and return
    if df.shape[0] == 0:
        raise RuntimeError('No sample table entries')

    # Get long-version of run accessions
    if 'Cell' in df.columns:
        df['CellLong'] = df['Cell'].apply(lambda val: '{:d}_{:s}'.format(ord(val[0]) - ord('A') + 1 , val))

    return df

def get_sample_table_record(sample_table, sample, protocol, run, cell):
    """
    Get an entry from the sample table.
    """

    # Get sheet name
    if protocol == 'hifi':
        sheet_name = 'HiFi'

    elif protocol == 'clr':
        sheet_name = 'CLR'

    else:
        raise RuntimeError('Unknown protocol: ' + protocol)

    # Read
    df = sample_table.set_index(['Sample', 'Protocol', 'Run', 'Cell'], drop=False)

    if (sample, protocol, run, cell) not in df.index:
        raise RuntimeError('No SampleTable entry: sample={}, run={}, cell={}'.format(sample, run, cell))

    entry = df.loc[(sample, protocol, run, cell)].squeeze()

    if not issubclass(pd.Series, entry.__class__):
        raise RuntimeError('Entry is not a Series. Duplicate Sample/Run/Cell?: sample={}, run={}, cell={}'.format(sample, run, cell))

    return entry


def get_sample_accession(sample):
    """
    Get BioSample accession for a sample by sample name.
    """

    sample_accession = pd.read_csv(
        'BiosampleTable.tsv', sep='\t', index_col='SampleID'
    ).loc[sample, 'Biosample']

    if pd.isnull(sample_accession):
        raise RuntimeError('Missing accession for sample: {}'.format(sample))

    return sample_accession

def get_hifi_experiment(sample):
    """
    Get experiment accession for a sample by sample name.
    """

    return pd.read_csv(
        'BiosampleTable.tsv', sep='\t', index_col='SampleID'
    ).loc[sample, 'ExperimentHifi']

def get_source_bam(sample_entry):
    """
    Locate the CCS bam for an entry.
    """

    # Find BAM
    dir_name = DIR_PATTERN[sample_entry['Protocol']].format(**sample_entry)

    if not os.path.isdir(dir_name):
        raise RuntimeError('No data directory: {}'.format(dir_name))

    file_name = os.path.join(dir_name, sample_entry['BAM'])

    if not os.path.isfile(file_name):
        raise RuntimeError('BAM file not found: {}'.format(file_name))

    #file_name = [file_name for file_name in os.listdir(dir_name) if file_name.endswith('.ccs.bam')]

    #if len(file_name) != 1:
    #    raise RuntimeError('Expected 1 BAM, found {}: {}'.format(len(file_name), dir_name))

    #return os.path.join(dir_name, file_name[0])

    return file_name
