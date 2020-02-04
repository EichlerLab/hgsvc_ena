"""
Rules for uploading data and XMLs to ENA.
"""

# ena_submit_run
#
# Submit to the ENA test system.
rule ena_submit_run:
    input:
        sub_xml='files/submission_add.xml',
        exp_xml='xml/runset/{sample}-{protocol}-experiment.xml',
        run_xml='xml/runset/{sample}-{protocol}-run.xml',
        upload_flag='submit/runset/{sample}-{protocol}/upload.flag'
    output:
        flag='submit/runset/{sample}-{protocol}/submit_{system}.flag'
    log:
        log='submit/runset/{sample}-{protocol}/submit_{system}.log',
        xml='submit/runset/{sample}-{protocol}/submit_{system}.xml'
    wildcard_constraints:
        system='test|live'
    run:

        # Get host
        if wildcards.system == 'test':
            host_name = 'wwwdev.ebi.ac.uk'

        elif wildcards.system == 'live':
            host_name = 'www.ebi.ac.uk'

        else:
            raise RuntimeError('Unknown EBI system for wildcard: {system}'.format(**wildcards))

        # Submit
        shell(
            """scripts/submit.sh {WEBIN_ID} {host_name} {log.xml} -F "SUBMISSION=@{input.sub_xml}" -F "EXPERIMENT=@{input.exp_xml}" -F "RUN=@{input.run_xml}" >{log.log} 2>&1 && """
            """date > {output.flag}"""
        )

        # Check submission
        sub_root = ET.parse(log.xml).getroot()

        success_flag = sub_root.attrib['success']

        if success_flag != 'true':
            raise RuntimeError('Submission failed: Success flag = {}'.format(success_flag))


# ena_submit_upload_run_all
#
# Upload all files for a run set.
rule ena_submit_upload_run_all:
    input:
        flag=lambda wildcards: [
            'submit/runset/{Sample}-{Protocol}/upload/{Run}-{Cell}.flag'.format(**sample_entry)
            for index, sample_entry in get_sample_table(wildcards.protocol, wildcards.sample).iterrows()
        ]
    output:
        flag='submit/runset/{sample}-{protocol}/upload.flag'
    shell:
        """date > {output.flag}"""

# ena_submit_run_upload
#
# Upload data to ENA.
rule ena_submit_run_upload:
    output:
        flag='submit/runset/{sample}-{protocol}/upload/{run}-{cell}.flag'
    log:
        'submit/runset/{sample}-{protocol}/upload/{run}-{cell}.log'
    run:

        sample_table = get_sample_table(wildcards.protocol)
        sample_entry = get_sample_table_record(sample_table, wildcards.sample, wildcards.protocol, wildcards.run, wildcards.cell)

        if wildcards.protocol == 'hifi' or wildcards.protocol == 'clr':
            source_file = get_source_bam(sample_entry)
            dest_file = UPLOAD_FILE_NAME_FORMAT_BAM.format(**sample_entry)
            dest_dir = os.path.dirname(dest_file)

        else:
            raise RuntimeError('Unknown protocol: {protocol}'.format(**wildcards))

        # Stage file into temp/staging by hardlink. File is renamed this way so Aspera can transfer it
        # with the correct name. It doesn't rename the same way cp does, the target is strictly a directory name.
        shell(
            """scripts/upload_data.sh {WEBIN_ID} {source_file} {dest_file} >{log} 2>&1 && """
            """date > {output.flag}"""
        )

        # shell(
        #     """mkdir -p temp/staging/{dest_dir}; """
        #     """cp -fl {source_file} temp/staging/{dest_file}; """
        #     """scripts/upload_data.sh {WEBIN_ID} temp/staging/{dest_file} {dest_dir} >{log} 2>&1 && """
        #     """date > {output.flag}"""
        # )
