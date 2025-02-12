# Preparing Data with Python

We **normalizes** the raw dataset by organizing it into multiple tables, ensuring a more structured and efficient database design. Additionally, we add specific columns to establish relationships between these tables.

```Python
import pandas as pd

orders = pd.read_csv(r'N:\SQL\Retail Supply Chain\datasets\raw_dataset.csv', encoding='windows-1254')
orders.columns
```

*Index([  
    'Row ID', 'Order ID', 'Order Date', 'Ship Date', 'Ship Mode',
       'Customer ID', 'Customer Name', 'Segment', 'Country', 'City', 'State',
       'Postal Code', 'Region', 'Retail Sales People', 'Product ID',
       'Category', 'Sub-Category', 'Product Name', 'Returned', 'Sales',
       'Quantity', 'Discount', 'Profit'],
      dtype='object')*

We create `State Code` column combining with others to create unique id for each location so that we can establish a relationship between `orders` table and `geographic_locations` table.

```Python
state_abbr = {
    'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR', 'California': 'CA',
    'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE', 'Florida': 'FL', 'Georgia': 'GA',
    'Hawaii': 'HI', 'Idaho': 'ID', 'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA', 'Kansas': 'KS',
    'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD', 'Massachusetts': 'MA',
    'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS', 'Missouri': 'MO', 'Montana': 'MT',
    'Nebraska': 'NE', 'Nevada': 'NV', 'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM',
    'New York': 'NY', 'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK',
    'Oregon': 'OR', 'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC', 'South Dakota': 'SD',
    'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT', 'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA',
    'West Virginia': 'WV', 'Wisconsin': 'WI', 'Wyoming': 'WY'
}

# Map with State Code.
orders.loc[:, 'State Code'] = orders['State'].map(state_abbr)

# Get unique id for each location.
orders['Location ID'] = orders['State Code'] + '-' + orders['City'] + '-' + orders['Postal Code'].astype(str)

customers = orders[['Customer ID', 'Customer Name', 'Segment']]
products = orders[['Product ID', 'Category', 'Sub-Category', 'Product Name']]
geographic_locations = orders[['Location ID', 'Country', 'State', 'State Code', 'City', 'Postal Code', 'Region']]

# Finish the orders table.
orders = orders[['Row ID', 'Order ID', 'Order Date', 'Ship Date', 'Ship Mode',
       'Customer ID', 'Retail Sales People', 'Product ID', 'Location ID', 'Returned', 'Sales',
       'Quantity', 'Discount', 'Profit']]
```

We remove duplicate values to ensure each table has a unique ID column and ensure that no duplicates remain.

For `customers` table.

```Python
# Drop duplicated values to create many to one relationship with orders table.
customers = customers.drop_duplicates(subset='Customer ID')

# Check any duplicated values left in the customers table.
customers[customers.duplicated()].any()
```

|                |               |
|----------------|---------------|
| *Customer ID*    | *False*         |
| *Customer Name*  | *False*         |
| *Segment*       | *False*        |

For `products` table.

```Python
products = products.drop_duplicates(subset='Product ID')
products[products.duplicated()].any()
```

|                |               |
|----------------|---------------|
|*Product ID*      | *False*         |
|*Category*       | *False*         |
|*Sub-Category*    | *False*         |
|*Product Name*    | *False*         |

For `geographic_locations` table.

```Python
geographic_locations = geographic_locations.drop_duplicates(subset='Location ID')
geographic_locations[geographic_locations.duplicated()].any()
````

|                |               |
|----------------|---------------|
|*Location ID*    |*False*          |
|*Country*         |*False*          |
|*City*            |*False*          |
|*State*           |*False*          |
|*State Code*      |*False*          |
|*Postal Code*     |*False*          |
|*Region*          |*False*          |

---

At this stage, we are ready to **export** all data tables to CSV files. To improve convenience, we create a function for exporting tables.

```Python
import os

def export_csv(tables_dict):
    for name, df in tables_dict.items(): 
        try:
            filepath = os.path.join(r"N:\SQL\Retail Supply Chain\datasets", f"{name}.csv")
            df.to_csv(filepath, encoding='utf-8', index=False)
            print(f"{name}.csv successfully exported.")
        except Exception as e:
            print(f"An error occurred while processing {name}: {e}")
    print("All exports are completed.")

export_csv({
    "orders": orders,
    "customers": customers,
    "products": products,
    "geographic_locations": geographic_locations
})
```

*orders.csv successfully exported.  
customers.csv successfully exported.  
products.csv successfully exported.  
geographic_locations.csv successfully exported.  
All exports are completed.*

[Here](reports/Setting%20Up%20SQL%20Database.md) we go to the next step.
