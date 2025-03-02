import gdown
import zipfile
import os
import pandas as pd
import shutil
import duckdb

def download_convert_to_csv():
    # URL for Google Drive file
    gdrive_url = 'https://drive.google.com/file/d/1mdJFW9E7YY5V5zG004K8M4sLEw84sYVL/view?usp=drive_link'
    file_id = gdrive_url.split('/d/')[1].split('/view')[0]
    direct_url = f'https://drive.google.com/uc?id={file_id}'
    
    # Create or clean output directory
    output_dir = 'task_3_data'
    if os.path.exists(output_dir):
        # Clear all files in the directory
        for file in os.listdir(output_dir):
            file_path = os.path.join(output_dir, file)
            if os.path.isfile(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        print(f"Cleaned directory: {output_dir}")
    else:
        os.makedirs(output_dir)
        print(f"Created directory: {output_dir}")
    
    # Download the zip file
    zip_path = os.path.join(output_dir, 'resources.zip')
    gdown.download(direct_url, zip_path, quiet=False)
    
    # Files to extract and convert
    excel_files = [
        'resources/task_3/supplier_data1.xlsx',
        'resources/task_3/supplier_data2.xlsx',
        'resources/task_3/buyer_preferences.xlsx'
    ]
    
    csv_files = []
    # Extract and convert each file
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        for excel_file in excel_files:
            # Extract file
            zip_ref.extract(excel_file, output_dir)
            
            # Get just the filename without path and extension
            base_name = os.path.basename(excel_file).split('.')[0]
            csv_file = os.path.join(output_dir, f"{base_name}.csv")
            
            # Read Excel and save as CSV
            excel_path = os.path.join(output_dir, excel_file)
            df = pd.read_excel(excel_path)
            df.to_csv(csv_file, index=False)
            
            csv_files.append(csv_file)
            print(f"Converted {excel_file} to {csv_file}")
    
    # Clean up extracted Excel files
    for subdir, dirs, files in os.walk(output_dir):
        for file in files:
            if file.endswith('.xlsx'):
                os.unlink(os.path.join(subdir, file))
    
    # Clean up the resources directory
    resources_dir = os.path.join(output_dir, 'resources')
    if os.path.exists(resources_dir):
        shutil.rmtree(resources_dir)
    
    # Remove the zip file
    os.unlink(zip_path)
    
    print(f"\nFiles converted and saved to: {output_dir}")
    for file in csv_files:
        print(f"- {file}")
    
    return csv_files


def load_data_to_duckdb(csv_files, database_name='task3.duckdb'):
    # Create a DuckDB connection and database
    conn = duckdb.connect(database_name)

    # Iterate through the CSV files and create tables
    for csv_file in csv_files:
        table_name = os.path.basename(csv_file).split('.')[0]  # Use file name without extension
        print(f"Loading {csv_file} into DuckDB as table {table_name}")
        
        # Check if schema exists before creating it
        schema_name = 'task_3_data'
        conn.execute(f"""
            CREATE SCHEMA IF NOT EXISTS {schema_name};
        """)

        # Drop the table if it already exists
        conn.execute(f"DROP TABLE IF EXISTS {schema_name}.{table_name};")

        # Load the CSV into a DuckDB table
        conn.execute(f"CREATE TABLE {schema_name}.{table_name} AS SELECT * FROM read_csv('{csv_file}')")
    
    print(f"\nData loaded successfully into {database_name} database")

    # Close the DuckDB connection
    conn.close()


if __name__ == "__main__":
    try:
        import pandas
    except ImportError:
        print("Installing pandas and openpyxl...")
        import pip
        pip.main(['install', 'pandas', 'openpyxl'])
    
    try:
        import gdown
    except ImportError:
        print("Installing gdown...")
        import pip
        pip.main(['install', 'gdown'])
    
    # Step 1: Download and convert the files
    converted_files = download_convert_to_csv()
    
    # Step 2: Load data into DuckDB
    load_data_to_duckdb(converted_files)
