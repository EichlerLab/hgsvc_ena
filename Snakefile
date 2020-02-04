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
