import snowflake.connector
import pandas as pd

# Replace these with your actual Snowflake credentials
conn = snowflake.connector.connect(
    user='your_username',
    password='your_password',
    account='your_account',
    warehouse='your_warehouse',
    database='your_database',
    schema='your_schema'
)

cur = conn.cursor()
cur.execute("""
    SELECT 
        DZMH.COUNTRY_NAME, 
        DZMH.CLUSTER_NAME, 
        COALESCE(OA.ONBOARDING_AREA, OA.CITY_NAME) AS ONBOARDING_AREA
    FROM production.AGGREGATE.AGG_ZONE_DELIVERY_METRICS_HOURLY AS DZMH
    LEFT JOIN scratch.riders.zone_drn_id_to_onboarding_area AS OA ON DZMH.ZONE_CODE = OA.ZONE_CODE
    WHERE DZMH.COUNTRY_NAME IN ('France', 'Italy', 'Belgium', 'UK', 'Ireland')
        AND ONBOARDING_AREA IS NOT NULL
    GROUP BY DZMH.COUNTRY_NAME, DZMH.CLUSTER_NAME, OA.ONBOARDING_AREA, OA.CITY_NAME
    ORDER BY DZMH.COUNTRY_NAME DESC, DZMH.CLUSTER_NAME, OA.ONBOARDING_AREA
""")

# This preserves the ordering from the SQL query
df = cur.fetch_pandas_all()

# Save to CSV while maintaining the order
df.to_csv('output.csv', index=False)

# Close the connection
cur.close()
conn.close()
