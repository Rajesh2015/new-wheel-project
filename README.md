# Vehicle Sales and Customer Satisfaction Analysis Using SQL

## Project Overview

This project uses SQL to analyze vehicle sales, customer purchasing preferences, customer feedback, discounts, and shipping performance. It addresses ten business questions to help a vehicle sales company understand its customer base, monitor quarterly performance, and identify areas for further investigation.

The analysis combines customer, vehicle, and order information to examine geographic demand, popular vehicle makers, revenue trends, and customer satisfaction.

> **Status:** This README documents the analysis scope and methodology. The dataset, database schema, query outputs, and numerical findings have not been provided, so no business results are claimed.

## Business Objectives

- Understand the geographic distribution of customers who have placed orders.
- Identify the most popular vehicle makers overall and within each state.
- Measure customer satisfaction and assess how feedback changes over time.
- Track quarterly orders, net revenue, and revenue growth.
- Compare discounts across credit card types.
- Evaluate the time taken to ship orders across quarters.

## Data Requirements

The following are logical data requirements; actual table and column names depend on the source schema.

| Data area | Required fields | Purpose |
| --- | --- | --- |
| Customers | Customer ID, state, credit card type | Customer counts, geographic distribution, and card comparisons |
| Vehicles | Vehicle/product ID, vehicle maker | Vehicle maker preferences |
| Orders and order items | Order ID, customer ID, vehicle/product ID, quantity, selling price, discount, feedback, order date, ship date, quarter number | Sales, satisfaction, and shipping analysis |

Customer and vehicle identifiers connect these data areas. Before joining tables, confirm their grain and key uniqueness to prevent duplicate counts or inflated revenue.

## Analysis Questions and Approach

| No. | Business question | SQL approach | Expected output |
| --- | --- | --- | --- |
| 1 | How many customers have placed orders, and how are they distributed across states? | Filter to customers with orders; use `COUNT(DISTINCT customer_id)` overall and by state. | Total purchasing customers and customer count per state |
| 2 | What are the top five vehicle makers preferred by customers? | Count distinct purchasing customers per maker, sort descending, and select the top five. | Vehicle maker and customer count |
| 3 | Which vehicle maker is most preferred in each state? | Aggregate distinct customers by state and maker; apply `RANK() OVER (PARTITION BY state ORDER BY customer_count DESC)` and keep rank 1. | Leading maker or tied makers for each state |
| 4 | What is the overall average customer rating and the average for each quarter? | Convert feedback to numeric ratings using `CASE` in a subquery, then calculate overall and quarterly averages. | Overall average rating and quarterly average ratings |
| 5 | What is the percentage distribution of feedback, and are customers becoming more dissatisfied? | Use conditional aggregation to calculate each feedback category as a percentage of valid feedback within each quarter. | Quarterly feedback percentages and evidence for any satisfaction trend |
| 6 | How does the number of orders change by quarter? | Count distinct order IDs by quarter and sort chronologically. | Quarterly order counts |
| 7 | What is the total net revenue and its quarter-over-quarter percentage change? | Aggregate discounted sales revenue; use `LAG()` on quarterly totals to calculate the change from the previous quarter. | Total net revenue, quarterly revenue, and quarterly growth rates |
| 8 | How do net revenue and order volumes trend together? | Calculate net revenue and distinct order counts within the same quarterly aggregation. | Quarterly revenue and order counts side by side |
| 9 | What is the average discount for each credit card type? | Join orders to the appropriate card information and calculate `AVG(discount)` by card type. | Average discount per credit card type |
| 10 | What is the average time taken to ship orders in each quarter? | Calculate the difference between order and shipping dates, then average by the order's quarter. | Average shipping lead time in days per quarter |

## Metric Definitions

### Purchasing Customers

Count each customer once when measuring the total customer base or customers within a state. A customer who buys from multiple makers can appear once under each maker, so maker-level counts may sum to more than the overall customer count.

### Customer Ratings

| Feedback | Numeric rating |
| --- | --- |
| Very Bad | 1 |
| Bad | 2 |
| Okay | 3 |
| Good | 4 |
| Very Good | 5 |

Calculate the overall rating from all valid rated observations rather than taking an unweighted average of quarterly averages. Exclude missing or unrecognized feedback from rating calculations and report its count separately. If feedback is attached to orders, these averages describe order feedback rather than giving each customer equal weight.

### Feedback Distribution

`Feedback percentage = 100 × category count / total valid feedback count in the quarter`

Assess dissatisfaction using the combined percentage of **Bad** and **Very Bad** feedback, together with the average rating and feedback sample size. A rising negative-feedback share across quarters would support a deterioration in satisfaction; the actual conclusion requires query results.

### Net Revenue

When discounts are stored as fractions, such as `0.10` for 10%:

`Net revenue = SUM(quantity × selling_price × (1 − discount))`

If discounts are stored as whole percentages, such as `10` for 10%, divide the discount by 100 first. If they are monetary amounts, adapt the formula to whether the discount applies per unit or per order. Use the transaction selling price where available and confirm how returns and cancellations should be treated.

### Quarter-over-Quarter Revenue Change

`QoQ change (%) = 100 × (current quarter revenue − previous quarter revenue) / previous quarter revenue`

The first quarter has no comparison and should return `NULL`. Use `NULLIF(previous_quarter_revenue, 0)` to avoid division by zero. Check for missing quarters so `LAG()` compares consecutive calendar quarters.

### Shipping Lead Time

`Shipping lead time = ship date − order date`

This measures the time until shipment, not delivery time. Exclude unshipped orders from the completed-shipment average and report them separately; investigate negative date differences.

## SQL Concepts Demonstrated

- Table joins and distinct customer/order counting
- Aggregations using `COUNT()`, `SUM()`, and `AVG()`
- Conditional aggregation and rating conversion using `CASE`
- Subqueries and common table expressions (CTEs)
- Window functions: `RANK()` and `LAG()`
- Percentage calculations and division-by-zero handling
- Date arithmetic, grouping, and chronological sorting

## Validation and Interpretation

- Verify table grain and join cardinality before aggregation, especially when one order has multiple items.
- Retain all first-place ties when using `RANK()` for state-level preferences.
- Confirm discount units, price definitions, and treatment of missing discounts before calculating revenue.
- Check feedback spelling and missing values before mapping ratings.
- Group and sort by year and quarter when the dataset spans multiple years.
- Use the database's appropriate date-difference syntax and decimal arithmetic for averages and percentages.
- Interpret revenue and order trends together; revenue can change because of order volume, quantities, prices, product mix, or discounts.

## How to Use This Project

1. Load the source dataset into a SQL database.
2. Inspect the schema, relationships, data types, and record grain.
3. Adapt the analysis to the actual table names and SQL dialect.
4. Execute the queries for the ten questions and validate the outputs.
5. Add the verified results, charts, and conclusions to the repository.

## Findings to Complete After Execution

- Total purchasing customers and states with the largest customer bases
- Top five makers and state-level preference patterns
- Overall rating and changes in quarterly negative-feedback percentages
- Quarterly order volumes, revenue, and revenue growth
- Differences in average discounts across card types
- Quarterly shipping lead times and any operational delays

Recommendations should follow the observed results. Potential actions include reviewing regional inventory, investigating declining feedback, evaluating discount effectiveness, and examining quarters with longer shipping lead times.
