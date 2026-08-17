import pandas as pd

monthly_actuals = pd.read_csv("C:/Users/user/Documents/budjet vs actual variance/data/processed/monthly_actuals_by_category.csv", sep=";")
print(monthly_actuals.head(10))


growth_rates = {
    'high': 0.10,
    'mid': 0.05,
    'low': 0.02,
}

high_keywords = ['computer', 'electronic', 'phone', 'tablet', 'console', 'game', 'audio']
low_keywords = ['home', 'furniture', 'garden', 'bed', 'bath', 'table', 'housewares', 'construction']


def assign_tier(category_name):
    name = str(category_name).lower()
    if any(k in name for k in high_keywords):
        return 'high'
    if any(k in name for k in low_keywords):
        return 'low'
    return 'mid'

monthly_actuals['tier'] = monthly_actuals['category'].apply(assign_tier)
monthly_actuals['growth_rate'] = monthly_actuals['tier'].map(growth_rates)

print(monthly_actuals.head())

monthly_actuals['year'] = monthly_actuals['month'].str[:4].astype(int)
monthly_actuals['month_num'] = monthly_actuals['month'].str[5:7].astype(int)

print(monthly_actuals.head())

prior = monthly_actuals[['category', 'year', 'month_num', 'revenue', 'units', 'avg_price']].copy()
prior['year'] = prior['year'] + 1  # shift forward so it lines up with next year's row
prior = prior.rename(columns={
    'revenue': 'prior_year_revenue',
    'units': 'prior_year_units',
    'avg_price': 'prior_year_avg_price'
})

print(prior.head())

merged = monthly_actuals.merge(prior, on=['category', 'year', 'month_num'], how='inner')
# inner join naturally drops Sept16-Aug17 (no prior year exists for them)

print(merged.head())

# Apply tier growth rate to get budget figures
merged['budget_revenue'] = merged['prior_year_revenue'] * (1 + merged['growth_rate'])
merged['budget_units'] = merged['prior_year_units'] * (1 + merged['growth_rate'])
merged['budget_avg_price'] = merged['budget_revenue'] / merged['budget_units']

print(merged.head())


out = merged[['month', 'category', 'tier', 'growth_rate',
              'budget_revenue', 'budget_units', 'budget_avg_price']].sort_values(['month', 'category'])

print(out.shape)
print(out.head())
print(out['tier'].value_counts())
print(out.groupby('tier')['category'].unique())

out.to_csv('C:/Users/user/Documents/budjet vs actual variance/data/processed/budget_assumptions.csv', index=False)


pd.set_option('display.max_colwidth', None)
for t in ['high', 'mid', 'low']:
    print(t, ':', sorted(monthly_actuals[monthly_actuals['tier'] == t]['category'].unique()))
    print()



