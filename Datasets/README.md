generate_schema.py - generates a json file that is used to generate queries 

generate_iceberg_tables.py - ingests table files and creates iceberg tables 
                           - ran with main_import.sh
                           - or the command at the bottom of the file

scale_dataset.py - using the logic from (DataManagementLab/zero-shot-cost-estimation) generate 

./schemas - directory containing schema overviews for all datasets used for scaling datasets that do not provide the functionality, along with generating queries

update_json_metadata.ipynb - update the metadata location of iceberg tables 
update_avro_metadata.ipynb - update the metadata location of iceberg tables 