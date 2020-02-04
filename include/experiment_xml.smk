"""
Rules and definitions for generating experiment XMLs.
"""

# ena_make_experiment_xml
#
# Make experiment XML.
rule ena_make_experiment_xml:
    output:
        xml='xml/runset/{sample}-{protocol}-experiment.xml'
    run:

        # Read sample table
        sample_table = get_sample_table(wildcards.protocol, sample=wildcards.sample)

        # Get center name
        if len(set(sample_table['Center'])) != 1:
            raise RuntimeError('Expected 1 center, found {}'.format(len(set(sample_table['Center']))))

        center_alias = list(set(sample_table['Center']))[0]

        if center_alias not in CENTER_NAME:
            raise RuntimeError('Center alias unknown: {}'.format(center_alias))

        center_name = CENTER_NAME[center_alias]
        center_name_pretty = CENTER_NAME_PRETTY[center_alias]

        # Setup experiment alias
        protocol_name = PROTOCOL_NAME[wildcards.protocol]

        experiment_alias = 'HGSVC_Reads_{sample}_{proto}_{center}'.format(
            sample=wildcards.sample,
            proto=PROTOCOL_NAME[wildcards.protocol],
            center=center_alias
        )

        # Make root element
        exp_set = ET.Element("EXPERIMENT_SET")

        # Add experiment
        experiment = ET.SubElement(
            exp_set, 'EXPERIMENT',
            alias=experiment_alias,
            center_name=center_name
        )

        # Add Title
        ET.SubElement(experiment, 'TITLE').text = 'HGSVC Reads: {sample} ({proto}, {center})'.format(
            sample=wildcards.sample,
            proto=PROTOCOL_NAME[wildcards.protocol],
            center=center_alias
        )

        # Add Study
        ET.SubElement(
            experiment, 'STUDY_REF',
            accession=ENA_STUDY
        )

        # Add design
        exp_design = ET.SubElement(experiment, 'DESIGN')

        # Design - Description
        ET.SubElement(
            exp_design, 'DESIGN_DESCRIPTION'
        ).text = DESIGN_DESCRIPTION[wildcards.protocol].format(
            sample=wildcards.sample,
            center=center_name_pretty
        )

        # Design - Sample descriptor
        ET.SubElement(
            exp_design, 'SAMPLE_DESCRIPTOR',
            accession=get_sample_accession(wildcards.sample)
        )

        # Design - Lib
        exp_design_lib = ET.SubElement(
            exp_design, 'LIBRARY_DESCRIPTOR'
        )

        # Design - Lib - Name
        ET.SubElement(
            exp_design_lib, 'LIBRARY_NAME'
        )

        # Design - Lib - Lib strategy
        ET.SubElement(
            exp_design_lib, 'LIBRARY_STRATEGY'
        ).text = ENA_LIBRARY_STRATEGY

        # Design - Lib - Lib source
        ET.SubElement(
            exp_design_lib, 'LIBRARY_SOURCE'
        ).text = ENA_LIBRARY_SOURCE

        # Design - Lib - Lib source
        ET.SubElement(
            exp_design_lib, 'LIBRARY_SELECTION'
        ).text = ENA_LIBRARY_SELECTION

        # Design - Lib - Layout
        ET.SubElement(
            ET.SubElement(exp_design_lib, 'LIBRARY_LAYOUT'),
            'SINGLE'
        )

        # Platform
        ET.SubElement(
            ET.SubElement(
                ET.SubElement(experiment, 'PLATFORM'),
                'PACBIO_SMRT'
            ),
            'INSTRUMENT_MODEL'
        ).text = 'Sequel II'

        # Write
        with open(output.xml, 'w') as out_file:
            out_file.write(
                minidom.parseString(
                    ET.tostring(exp_set)
                ).toprettyxml(indent='  ')
            )

        # Validate
        shell(
            """xmllint --noout --schema files/SRA.experiment.xsd {output.xml}"""
        )
