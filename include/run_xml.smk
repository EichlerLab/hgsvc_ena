"""
Rules and definitions for generating run XMLs.
"""


#
# Declarations
#

def add_pacbio_run(run_set, sample_entry):
    """
    Add a run to a run set.

    :param run_set: Run set ElementTree root element.
    :param sample_entry: One record from the sample table as a Pandas Series object.
    """

    ### Init ###

    # Check protocol
    if sample_entry['Protocol'] != 'hifi' and sample_entry['Protocol'] != 'clr':
        raise RuntimeError('Protocol not supported: ' + sample_entry['Protocol'])

    UPLOAD_FILE_NAME_FORMAT = UPLOAD_FILE_NAME_FORMAT_BAM

    # Check MD5
    file_md5 = sample_entry['MD5'].strip() if not pd.isnull(sample_entry['MD5']) else ''

    if not file_md5:
        raise RuntimeError('Missing MD5: sample={Sample}, proto={Protocol}, run={Run}, cell={Cell}'.format(**sample_entry))

    # Get experiment
    experiment_alias = 'HGSVC_Reads_{sample}_{proto}_{center}'.format(
        sample=sample_entry['Sample'],
        proto=PROTOCOL_NAME[sample_entry['Protocol']],
        center=sample_entry['Center']
    )

#    ena_experiment_accession = get_hifi_experiment(sample_entry['Sample']).strip() if not pd.isnull(sample_entry['Sample']) else ''
#
#    if not ena_experiment_accession:
#        raise RuntimeError('No experiment accession: sample={Sample}, proto={Protocol}, run={Run}, cell={Cell}'.format(**sample_entry))


    ### Construct entry ###

    # Add run element
    run_element = ET.SubElement(
        run_set, 'RUN',
        alias='{sample}-{proto}-{run}-{cell}'.format(
            sample=sample_entry['Sample'],
            run=sample_entry['Run'],
            cell=sample_entry['Cell'],
            proto=PROTOCOL_NAME[sample_entry['Protocol']]
        ),
        center_name=CENTER_NAME[sample_entry['Center']]
    )

    # Add title
    if sample_entry['Protocol'] == 'hifi':
        ET.SubElement(run_element, 'TITLE').text = 'HGSVC HiFi {Sample} - {Run} {Cell}'.format(**sample_entry)
        
    elif sample_entry['Protocol'] == 'clr':
        ET.SubElement(run_element, 'TITLE').text = 'HGSVC CLR {Sample} - {Run} {Cell}'.format(**sample_entry)
        
    else:
        raise RuntimeError('Unknown protocol: ' + sample_entry['protocol'])

    # Add experiment reference
    #exp_ref = ET.SubElement(run_element, 'EXPERIMENT_REF', accession=ena_experiment_accession)
    exp_ref = ET.SubElement(run_element, 'EXPERIMENT_REF', refname=experiment_alias)

    #ET.SubElement(ET.SubElement(exp_ref, 'IDENTIFIERS'), 'PRIMARY_ID').text = ena_experiment_accession

    # Data block
    files_element = ET.SubElement(ET.SubElement(run_element, 'DATA_BLOCK'), 'FILES')

    ET.SubElement(
        files_element, 'FILE',
        filename=UPLOAD_FILE_NAME_FORMAT.format(**sample_entry),
        filetype='bam',
        checksum_method='MD5',
        checksum=file_md5
    )


    ### Attributes (optional) ###

    # Parse attributes
    attrib_list = list()
    
    attr_center = CENTER_NAME[sample_entry['Center']]
    attr_lib = sample_entry['Library name'].strip() if not pd.isnull(sample_entry['Library name']) else None
    attr_chem = sample_entry['Chemistry'].strip() if not pd.isnull(sample_entry['Chemistry']) else None
    attr_lib_len = sample_entry['Library Len (Mean bp)'] if not pd.isnull(sample_entry['Library Len (Mean bp)']) else None
    attr_notes = sample_entry['Notes'].strip() if not pd.isnull(sample_entry['Notes']) else None
    
    attrib_list.append(('Center', attr_center))
    
    if attr_lib is not None:
        attrib_list.append(('LibraryName', attr_lib))

    if attr_chem is not None:
        attrib_list.append(('Chemistry', attr_chem))

    if attr_lib_len is not None:

        try:
            attr_lib_len = '{:,d} bp'.format(np.int32(attr_lib_len))
        except ValueError:
            attr_lib_len = str(attr_lib_len).strip()

        if attr_lib_len:
            attrib_list.append(('LibraryInsertLength', attr_lib_len))

    if attr_notes is not None:
        attrib_list.append(('Notes', attr_notes))

    # Add attributes
    if attrib_list:

        attrib_element_container = ET.SubElement(run_element, 'RUN_ATTRIBUTES')

        for attr_key, attr_val in attrib_list:

            attrib_element = ET.SubElement(attrib_element_container, 'RUN_ATTRIBUTE')

            ET.SubElement(attrib_element, 'TAG').text = attr_key
            ET.SubElement(attrib_element, 'VALUE').text = attr_val

#
# Rules
#

# ena_make_run_xml
#
# Make run XML.
rule ena_make_run_xml:
    output:
        xml='xml/runset/{sample}-{protocol}-run.xml'
    run:

        # Get add_run function
        if wildcards.protocol == 'hifi' or wildcards.protocol == 'clr':
            add_run = add_pacbio_run

        else:
            raise RuntimeError('Unknown protocol: {protocol}'.format(**wildcards))

        # Read sample table
        sample_table = get_sample_table(wildcards.protocol)

        sample_table = sample_table.loc[sample_table['Sample'] == wildcards.sample]

        if sample_table.shape[0] == 0:
            raise RuntimeError('No samples: {sample}, protocol={protocol}'.format(**wildcards))

        # Make root element
        run_set = ET.Element("RUN_SET")

        # Add run elements
        for index, sample_entry in sample_table.iterrows():
            add_run(run_set, sample_entry)

        # Write
        with open(output.xml, 'w') as out_file:
            out_file.write(
                minidom.parseString(
                    ET.tostring(run_set)
                ).toprettyxml(indent='  ')
            )

        # Validate
        shell(
            """xmllint --noout --schema files/SRA.run.xsd {output.xml}"""
        )
