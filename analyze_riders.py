import pandas as pd
import numpy as np
from datetime import datetime
import os

# Read the CSV file
df = pd.read_csv('/Users/jono/Downloads/disabled_onboards.csv')
print("\nFirst few rows of the data:")
print(df.head())

# Clean the data
df['ORDERS_DELIVERED_CUMULATIVE'] = df['ORDERS_DELIVERED_CUMULATIVE'].replace(['\\N', '\\\\N'], 0)
df['ORDERS_DELIVERED_CUMULATIVE'] = pd.to_numeric(df['ORDERS_DELIVERED_CUMULATIVE'], errors='coerce').fillna(0)

# Convert date columns to datetime
date_columns = ['STATUS_DATE', 'ONBOARDING_AT_DATE', 'CREATED_IN_RIDER_ADMIN_AT_DATE']
for col in date_columns:
    df[col] = pd.to_datetime(df[col])

# Function to check if a rider was previously disabled/terminated
def was_previously_disabled(group):
    if len(group) > 1:
        statuses = group['CUR_ADMIN_STATUS'].tolist()
        return any(status in ['DISABLED', 'TERMINATED'] for status in statuses if status != '\\N')
    return False

# Function to analyze rider status
def analyze_rider_status(df):
    # Active riders (status is null)
    active_riders = df[df['CUR_ADMIN_STATUS'] == '\\N']
    
    # Disabled/Terminated riders
    disabled_riders = df[df['CUR_ADMIN_STATUS'].isin(['DISABLED', 'TERMINATED'])]
    
    # Riders with grace period expired
    grace_period_expired = df[
        df['RIDER_ADMIN_STATUS_NOTE'].str.contains('conditional onboarding grace period expired', 
                                                  case=False, na=False)
    ]
    
    # Reactivated riders (previously disabled/terminated, now active)
    reactivated_riders = df.groupby('DRIVER_ID').filter(was_previously_disabled)
    reactivated_riders = reactivated_riders[reactivated_riders['CUR_ADMIN_STATUS'] == '\\N']
    
    return {
        'active': active_riders,
        'disabled': disabled_riders,
        'grace_period_expired': grace_period_expired,
        'reactivated': reactivated_riders
    }

# Function to analyze orders
def analyze_orders(df):
    return {
        'with_orders': df[df['ORDERS_DELIVERED_CUMULATIVE'] > 0],
        'without_orders': df[df['ORDERS_DELIVERED_CUMULATIVE'] == 0]
    }

# Create a directory for results if it doesn't exist
if not os.path.exists('analysis_results'):
    os.makedirs('analysis_results')

# Overall Analysis
status_groups = analyze_rider_status(df)
overall_stats = pd.DataFrame({
    'Metric': ['Total Riders', 'Active Riders', 'Disabled/Terminated Riders', 'Grace Period Expired', 'Reactivated Riders'],
    'Count': [len(df), len(status_groups['active']), len(status_groups['disabled']), 
              len(status_groups['grace_period_expired']), len(status_groups['reactivated'])]
})
overall_stats.to_csv('analysis_results/overall_analysis.csv', index=False)

# Order Analysis
disabled_orders = analyze_orders(status_groups['disabled'])
reactivated_orders = analyze_orders(status_groups['reactivated'])

order_stats = pd.DataFrame({
    'Category': ['Disabled/Terminated - With Orders', 'Disabled/Terminated - Without Orders',
                'Reactivated - With Orders', 'Reactivated - Without Orders'],
    'Count': [len(disabled_orders['with_orders']), len(disabled_orders['without_orders']),
              len(reactivated_orders['with_orders']), len(reactivated_orders['without_orders'])]
})
order_stats.to_csv('analysis_results/order_analysis.csv', index=False)

# Analysis by Onboarding Area
area_stats = []
for area in df['ONBOARDING_AREA'].unique():
    area_df = df[df['ONBOARDING_AREA'] == area]
    area_status = analyze_rider_status(area_df)
    
    area_stats.append({
        'Onboarding Area': area,
        'Total Riders': len(area_df),
        'Active': len(area_status['active']),
        'Disabled/Terminated': len(area_status['disabled']),
        'Grace Period Expired': len(area_status['grace_period_expired']),
        'Reactivated': len(area_status['reactivated'])
    })

area_stats_df = pd.DataFrame(area_stats)
area_stats_df.to_csv('analysis_results/area_analysis.csv', index=False)

# Analysis by Vehicle Type
vehicle_stats = []
for vtype in df['VEHICLE_TYPE'].unique():
    vtype_df = df[df['VEHICLE_TYPE'] == vtype]
    vtype_status = analyze_rider_status(vtype_df)
    
    vehicle_stats.append({
        'Vehicle Type': vtype,
        'Total Riders': len(vtype_df),
        'Active': len(vtype_status['active']),
        'Disabled/Terminated': len(vtype_status['disabled']),
        'Grace Period Expired': len(vtype_status['grace_period_expired']),
        'Reactivated': len(vtype_status['reactivated'])
    })

vehicle_stats_df = pd.DataFrame(vehicle_stats)
vehicle_stats_df.to_csv('analysis_results/vehicle_analysis.csv', index=False)

print("Analysis complete! Results have been saved to the 'analysis_results' directory:")
print("1. overall_analysis.csv - Overall statistics")
print("2. order_analysis.csv - Order completion analysis")
print("3. area_analysis.csv - Analysis by onboarding area")
print("4. vehicle_analysis.csv - Analysis by vehicle type")
print("\nYou can import these CSV files directly into Google Sheets.") 