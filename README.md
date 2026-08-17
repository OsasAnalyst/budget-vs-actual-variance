# Budget vs Actual Variance Analysis

I built this project to answer the question every finance team runs into every month: not just did we beat or miss budget, but why. A revenue beat driven by price is a different story than one driven by volume, and a flat commentary list with fifty line items in it doesn't get read by anyone. This model takes real transaction data, measures it against a documented budget baseline, and isolates the drivers using Price-Volume-Mix analysis and materiality-filtered OpEx flux, the same framework you'd see in a real monthly variance pack.

## Why This Matters

Most variance reporting stops at a single number: revenue was up or down X percent. That tells leadership almost nothing about what to do next. A category that beat budget on volume needs more inventory and ad spend behind it. A category that beat budget on price alone might not repeat next month. Reviewing every line that moved is also a waste of a CFO's time, most of what moves in a given month isn't material enough to explain. This model solves both problems: it breaks revenue variance into Price, Volume, and Mix at the category level, and it only surfaces the lines, on both the revenue and OpEx side, that clear a dual dollar-and-percentage materiality threshold.

## Data Source

Actuals come from the Olist Brazilian e-commerce dataset (Kaggle), real anonymized order, payment, item, and product data covering September 2016 through August 2018. I used four of the raw tables: orders, order_items, order_payments, and products, plus a category translation table to convert the raw Portuguese category names to English. Only orders with a status of "delivered" are counted as revenue actuals, since a shipped order only confirms dispatch, not that the customer received and kept it.

I reused this dataset from an earlier cash flow project in the same portfolio, since it has real order-level detail with product categories, which is what category-level PVM analysis needs.

## Approach

Actuals are 100 percent real, aggregated to category and month from the Olist tables. The budget is built from a same-month-prior-year baseline (September 2017 actuals against September 2016, for example) with a documented growth rate layered on top, not a real forecast pulled from a planning system. I chose same-month-prior-year over a rolling prior-month baseline specifically to control for seasonality, e-commerce has real spikes around November and December that a rolling baseline would misread as performance rather than seasonality.

That distinction matters and I want to be upfront about it: this is a real historical result measured against a planned, assumption-driven number, the same setup as comparing actuals to a board-approved budget.

## Assumptions

I'm listing every assumption made in this project so nothing here is a black box.

**Budget growth rates.** Each of the 74 categories is bucketed into one of three growth tiers based on keyword matching against category type: high growth at 10 percent (electronics, computers, audio, tablets and similar), low growth at 2 percent (bed and bath, furniture, garden, construction and similar, 19 categories), and mid growth at 5 percent as the default for everything else, including a few categories the keyword match didn't cleanly catch. The rate is applied flat rather than as a monthly curve, on purpose, so the budget doesn't end up looking reverse-engineered to fit the actuals.

**Data coverage gaps.** September 2016 through August 2017 has no budget at all, since there's no prior-year anchor to build it from, and is excluded rather than fabricated. November 2017 has no OpEx budget either, because its anchor month, November 2016, had zero delivered orders in the source data, a genuine ramp-up-era gap in the dataset, not a pipeline bug. January 2018 also carries an unusually large variance percentage (roughly 692 percent) purely because its budget coverage is still thin that early in the model's window. All of this is flagged in the workbook itself, not just here.

**Materiality thresholds.** A revenue variance is only flagged if it clears both a dollar threshold ($5,000) and a percentage threshold (5 percent) at the same time, except for unbudgeted categories, which are flagged on the dollar threshold alone since a percentage variance against a zero budget is meaningless. OpEx uses the same dual-threshold logic at a $1,000 and 5 percent level. This keeps the commentary table focused on what's actually worth a conversation instead of every category that moved.

**OpEx actuals.** Payroll, rent, ad spend, and logistics are simulated, not pulled from a real ERP or accounting system. Payroll and rent are flat monthly figures, ad spend is 6 percent of the month's budgeted revenue, and logistics is a per-unit rate against budgeted units. Actuals are generated as the budget figure plus random noise, seeded for reproducibility, with no built-in bias in either direction. Olist has no expense data, so this layer exists to demonstrate the flux framework end to end, not to represent a real company's cost structure.

**Category segmentation.** Categories follow Olist's own product taxonomy (translated from Portuguese), which is what makes category-level PVM possible in the first place. About 1.3 percent of revenue falls into an "uncategorized" bucket where no clean category mapping exists, which I judged immaterial and left as is rather than force-fitting it somewhere.

**Revenue variance math.** Standard PVM formulas: Price Effect = (actual price minus budget price) multiplied by actual units. Volume Effect = (actual units minus budget units) multiplied by budget price. At the total level, the residual between total variance and Price plus Volume captures both true category mix shift and revenue from categories that had no budget at all, since both of those show up in the same place mathematically. I labeled that line "Mix/Unbudgeted Effect" rather than pretend it's pure mix.

## Project Structure

```
budget-vs-actual-variance/
├── README.md
├── data/
│   ├── raw/
│   │   └── (Olist orders, order_items, order_payments, products, category translation)
│   └── processed/
│       ├── monthly_actuals_by_category.csv
│       ├── budget_assumptions.csv
│       └── opex_budget_and_actuals.csv
├── sql/
│   ├── 01_schema_and_load.sql
│   └── 02_monthly_actuals_by_category.sql
├── python/
│   ├── 01_budget_assumptions.py
│   └── 02_opex_actuals_simulation.py
├── model/
│   └── variance_dashboard.xlsx
└── output/
    └── monthly_variance_report.docx
```

## How the Pieces Fit Together

The SQL layer loads the raw Olist tables into MySQL and builds the monthly actuals by category, filtered to delivered orders only. Python takes over from there: one script builds the budget baseline from same-month-prior-year actuals plus the documented growth tiers, the other simulates the OpEx actuals against documented OpEx assumptions. Both outputs feed into the Excel workbook, which follows an input, calc, output tab structure. The input tabs (`i_Setup`, `i_Actuals`, `i_Budget`, `i_OpexActuals`) hold the month selector, materiality thresholds, and raw data loads. The calc tabs (`c_RevenuePVM`, `c_OpexFlux`) run the Price/Volume/Mix math and the budget-vs-actual flux by expense line. The output tabs (`o_VarianceBridge`, `o_FluxCommentary`, `o_Dashboard`) turn that into a waterfall chart from Budget to Actual, a commentary table of flagged lines only, and a KPI dashboard with a month selector and trend view. The last step is a written monthly variance memo built directly from the dashboard's numbers.

## Key Outputs

- Revenue variance decomposed into Price, Volume, and Mix/Unbudgeted effects, at the category level and rolled up
- OpEx variance by line item with favorable/unfavorable flagging
- A native Excel waterfall bridge from Budget to Actual
- A materiality-filtered flux commentary table, revenue and OpEx combined
- A live Excel dashboard with a month selector, KPI cards, and a 12-month trend view
- A CFO-style written memo (`output/monthly_variance_report.docx`)

## Future Work

This version proves the framework end to end, but there's a clear next step if I were to take this into a real client engagement.

The biggest one is connecting to a real ERP or accounting system for both revenue actuals and OpEx actuals, instead of Olist data and simulated expense lines. That alone would turn this from a proof of concept into something a finance team could run every month against their own numbers.

I'd also want to add headcount and other operating metrics into the variance analysis, since OpEx flux alone doesn't capture things like productivity or cost-per-employee trends that usually sit next to a variance pack in a real board deck.

Beyond that, I'd build a forecasting module that feeds off the variance insights, so a category that's consistently beating a flat growth assumption gets reflected in next month's budget instead of flagging as a surprise every time. I'd also automate the monthly refresh so the dashboard updates as new data lands rather than being a one-time build, and extend the framework to cover cash flow variance alongside revenue and OpEx.

## Getting Started

1. Clone the repository and pull the raw Olist CSVs into `data/raw/`.
2. Run the SQL scripts in `sql/` in order against a MySQL instance to build the schema and the monthly actuals table.
3. Run the Python scripts in `python/` in order to generate the budget assumptions and the simulated OpEx actuals.
4. Open `model/variance_dashboard.xlsx`, refresh the Power Query connections, and select a month from the dropdown on `i_Setup`.

**Dependencies:** Python 3, pandas, numpy, openpyxl, sqlalchemy, and a MySQL instance for the SQL layer.

## Output Deliverable

The final output is `output/monthly_variance_report.docx`, a CFO-style memo that walks through the month's revenue variance by category, the flagged OpEx lines, the net impact on the bottom line, and specific recommended actions, written the way I'd actually send it to a CEO ahead of a leadership review.

## Contact

**Osaretin Idiagbonmwen**
Email: idiagbonmwenosaretin@gmail.com
LinkedIn: https://www.linkedin.com/in/osaretin-idiagbonmwen-33ab85339/
