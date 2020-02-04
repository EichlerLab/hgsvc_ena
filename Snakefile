"""
Prepare and submit to ENA
"""

import numpy as np
import os
import pandas as pd

import xml.etree.ElementTree as ET
from xml.dom import minidom

shell.prefix('set -euo pipefail; ')


#
# Include (definitions, rules, functions)
#

include: 'include/definitions.smk'
include: 'include/run_xml.smk'
include: 'include/experiment_xml.smk'
include: 'include/upload.smk'


# ena_summary
#
# Print a summary of all cells.
rule ena_summary:
    run:

        flag_pattern = 'results/{Sample}-{Protocol}-{Run}-{Cell}/submit.flag'

        # Read sample table
        df = pd.read_excel('SampleTable.xlsx')

        df['FLAG_FILE'] = df.apply(lambda row: flag_pattern.format(**row), axis=1)
        df['FLAG'] = df['FLAG_FILE'].apply(lambda val: os.path.isfile(val))

        print('Done:')
        for index, row in df.loc[df['FLAG']].iterrows():
            print('{FLAG_FILE}'.format(**row))

        print('\nNot Done:')
        for index, row in df.loc[~ df['FLAG']].iterrows():
            print('{FLAG_FILE}'.format(**row))
