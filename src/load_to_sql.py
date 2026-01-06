import os
from sqlalchemy import create_engine, inspect
import pandas as pd

def upload_dataframe(df, table_name):
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    # combine root_dir with db_path in order to run code from anywhere
    db_path = os.path.join(root_dir, 'data', 'processed', 'transport_weather.db')
    
    # create directory if it doesn't exist
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    engine = create_engine(f'sqlite:///{db_path}')
    
    # upload df to its table and if exists replace (only that table)
    print(f'Connecting to database at: {db_path}')
    df.to_sql(table_name, con=engine, if_exists='replace', index=False)
    
    # verify what's inside the file now
    inspector = inspect(engine)
    print(f"Table '{table_name}' uploaded.")
    print(f'Current tables in DB: {inspector.get_table_names()}')