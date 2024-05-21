import pandas as pd
from sqlalchemy import create_engine
import os

CONNECTION_URL = os.getenv('CONNECTION_URL')
db = create_engine(CONNECTION_URL)
conn = db.connect()

files = ['brands', 'categories', 'customers', 'order_items', 'orders', 'products', 'staffs', 'stocks', 'stores']

for file in files:
    df = pd.read_csv(f'F:/SQL/Bike-Store-SQL/files/{file}.csv')
    df.to_sql(file, con=conn, if_exists='replace', index=False)
