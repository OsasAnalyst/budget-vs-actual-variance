import pandas as pd
import numpy as np

np.random.seed(42)

df = pd.read_csv('C:/Users/user/Documents/budjet vs actual variance/data/processed/budget_assumptions.csv')

# 2017-11 is absent from budget_assumptions.csv and therefore from
# this file (11 months, not 12). Root cause: Nov 2017's YoY anchor, Nov 2016, has
# zero delivered-order records in the source data (2016-09: 1 row, 2016-10: 30 rows,
# 2016-11: 0 rows, 2016-12: 1 row), consistent with marketplace ramp-up gaps early
# in the dataset. This is a genuine gap in the source data, not a pipeline bug.

monthly = df.groupby('month')[['budget_revenue', 'budget_units']].sum().reset_index()
print(monthly.head())


# Define fixed opex amounts + variable opex rates 
payroll_monthly = 45000     
rent_monthly = 8000        
ad_spend_pct_of_revenue = 0.06   
logistics_per_unit = 4.50  



monthly['payroll_budget'] = payroll_monthly
monthly['rent_budget'] = rent_monthly
monthly['ad_spend_budget'] = monthly['budget_revenue'] * ad_spend_pct_of_revenue
monthly['logistics_budget'] = monthly['budget_units'] * logistics_per_unit

print(monthly.head())

# Simulate actuals with noise per line
noise_std = {
    'payroll': 0.02,     
    'rent': 0.01,         
    'logistics': 0.08,    
    'ad_spend': 0.15,     
}

n = len(monthly)
for line in ['payroll', 'rent', 'ad_spend', 'logistics']:
    noise = np.random.normal(loc=0, scale=noise_std[line], size=n)
    monthly[f'{line}_actual'] = monthly[f'{line}_budget'] * (1 + noise)

print(monthly.head())


# Reshape to long format
records = []
for line in ['payroll', 'rent', 'ad_spend', 'logistics']:
    tmp = monthly[['month', f'{line}_budget', f'{line}_actual']].copy()
    tmp = tmp.rename(columns={f'{line}_budget': 'budget', f'{line}_actual': 'actual'})
    tmp['line_item'] = line
    records.append(tmp)

print(records)

opex_long = pd.concat(records, ignore_index=True)
opex_long['variance'] = opex_long['actual'] - opex_long['budget']
opex_long['variance_pct'] = opex_long['variance'] / opex_long['budget']
opex_long = opex_long[['month', 'line_item', 'budget', 'actual', 'variance', 'variance_pct']]
opex_long = opex_long.sort_values(['month', 'line_item'])

print(opex_long.head())
print(opex_long.shape)

opex_long.to_csv('C:/Users/user/Documents/budjet vs actual variance/data/processed/opex_actuals_simulation.csv', index=False)