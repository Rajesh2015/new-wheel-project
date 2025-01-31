-- Question 1:
-- Find the total number of customers who have placed orders.
select * from ((SELECT 
    COUNT(DISTINCT customer_id) AS no_of_customers_placed_orders
FROM 
    gl_project.order_t) b
 inner join   
(SELECT 
    COUNT(DISTINCT state) AS no_of_states
FROM 
    gl_project.customer_t)a   
    on 1=1);
SELECT 
    COUNT(DISTINCT state) AS no_of_states
FROM 
    gl_project.customer_t;    

-- What is the distribution of the customers across states?
-- Hint: For each state, count the number of customers.
SELECT 
    a.state,
    a.no_of_customers,
    b.total_no_of_customers_placed_orders_across_all_states
FROM 
    (SELECT 
         state,
         COUNT(DISTINCT customer_id) AS no_of_customers
     FROM 
         gl_project.customer_t
     GROUP BY 
         state) a
INNER JOIN 
    (SELECT 
         COUNT(DISTINCT customer_id) AS total_no_of_customers_placed_orders_across_all_states
     FROM 
         gl_project.order_t) b 
ON 
    1 = 1
ORDER BY 
    a.no_of_customers DESC;


-- Question 2:
-- Which are the top 5 vehicle makers preferred by the customers?
-- Hint: For each vehicle maker, count the number of orders placed by customers.
SELECT 
    P1.vehicle_maker,
    COUNT(O.order_id) AS total_orders
FROM 
    gl_project.product_t P1
INNER JOIN 
    gl_project.order_t O
ON 
    P1.product_id = O.product_id
GROUP BY 
    P1.vehicle_maker
ORDER BY 
    total_orders DESC
LIMIT 10;

-- Question 3:
-- Which is the most preferred vehicle maker in each state? [4 marks]
-- Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
-- After ranking, take the vehicle maker whose rank is 1.
WITH StateVehicleOrders AS (
    SELECT 
        C.state,
        P.vehicle_maker,
        COUNT(C.customer_id) AS total_customers
    FROM 
        gl_project.product_t P
    INNER JOIN 
        gl_project.order_t O
    ON 
        P.product_id = O.product_id
    INNER JOIN
        gl_project.customer_t C
    ON 
        O.customer_id = C.customer_id
    GROUP BY 
        C.state, P.vehicle_maker
),
RankedStateVehicles AS (
    SELECT 
        state,
        vehicle_maker,
        total_customers,
        RANK() OVER (PARTITION BY state ORDER BY total_customers DESC) AS vehicle_rank
    FROM 
        StateVehicleOrders
)
SELECT 
    state,
    vehicle_maker,
    total_customers
FROM 
    RankedStateVehicles
WHERE 
    vehicle_rank = 1
ORDER BY 
    total_customers DESC;


-- Question 4:
-- Find the overall average rating given by the customers. What is the average rating in each quarter? [5 marks]
-- Consider the following mapping for ratings:
-- “Very Bad”: 1, “Bad”: 2, “Okay”: 3, “Good”: 4, “Very Good”: 5
-- Hint: Use subquery and assign numerical values to feedback categories using a CASE statement. 
-- Then, calculate the average feedback count per quarter. Use a subquery to convert feedback 
-- into numerical values and group by quarter_number to compute the average.
WITH FeedbackRatings AS (
    SELECT
        customer_feedback,
        quarter_number,
        CASE
            WHEN customer_feedback = 'very bad' THEN 1
            WHEN customer_feedback = 'bad' THEN 2
            WHEN customer_feedback = 'okay' THEN 3
            WHEN customer_feedback = 'good' THEN 4
            WHEN customer_feedback = 'very good' THEN 5
        END AS feedback_rating
    FROM 
        gl_project.order_t
),
QuarterlyAverage AS (
    SELECT 
        quarter_number,
        ROUND(AVG(feedback_rating), 2) AS average_feedback_rating
    FROM 
        FeedbackRatings
    GROUP BY 
        quarter_number
),
OverallAverage AS (
    SELECT 
        ROUND(AVG(feedback_rating), 2) AS overall_feedback_rating
    FROM 
        FeedbackRatings
)
SELECT 
    qa.quarter_number,
    qa.average_feedback_rating,
    oa.overall_feedback_rating
FROM 
    QuarterlyAverage qa
INNER JOIN 
    OverallAverage oa
ON 
    1=1
ORDER BY 
    qa.quarter_number ASC;

    


    
-- Question 5:
-- Find the percentage distribution of feedback from the customers. Are customers getting more dissatisfied over time? [5 marks]
-- Hint: Calculate the percentage of each feedback type by using conditional aggregation. 
-- For each feedback category, use a CASE statement to count the occurrences and then divide by the total count of feedback for the quarter, multiplied by 100 to get the percentage. 
-- Finally, group by quarter_number and order the results to reflect the correct sequence.
SELECT
    quarter_number,
    COUNT(customer_feedback) AS total_feedback,
    ROUND(
        SUM(CASE WHEN customer_feedback = 'very bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 
        2
    ) AS very_bad_percentage,
    ROUND(
        SUM(CASE WHEN customer_feedback = 'bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 
        2
    ) AS bad_percentage,
    ROUND(
        SUM(CASE WHEN customer_feedback = 'okay' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 
        2
    ) AS okay_percentage,
    ROUND(
        SUM(CASE WHEN customer_feedback = 'good' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 
        2
    ) AS good_percentage,
    ROUND(
        SUM(CASE WHEN customer_feedback = 'very good' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 
        2
    ) AS very_good_percentage
FROM 
    gl_project.order_t
GROUP BY 
    quarter_number
ORDER BY 
    quarter_number ASC;

-- - The **very bad percentage** increases over time (10.97 → 14.89 → 17.90 → 30.65).
-- - The **bad percentage** also increases (11.29 → 14.12 → 22.71 → 29.15).
-- - Meanwhile, the **good percentage** and **very good percentage** decrease significantly over the same periods.

-- This indicates that **customers are indeed becoming more dissatisfied over time**, as evidenced by the increasing percentages of negative feedback (`very bad` and `bad`) and the declining percentages of positive feedback (`good` and `very good`). 

-- The trend is clear and supports your observation.

-- Question 6:
-- What is the trend of the number of orders by quarter? [3 marks]
-- Hint: Count the number of orders for each quarter.
SELECT
    quarter_number,
    count(order_id) as total_orders
FROM 
    gl_project.order_t
GROUP BY 
    quarter_number
ORDER BY 
    quarter_number ASC;


-- Question 7:
-- Calculate the net revenue generated by the company. What is the quarter-over-quarter % change in net revenue? [5 marks]
-- Hint: Net Revenue is the amount obtained by multiplying the number of units sold by the price after deducting the discounts applied.
-- Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
-- Calculate the revenue for each quarter by summing the quantity of product and the discounted vehicle price. Use the LAG function to get the revenue from the previous quarter, and then compute the quarter-over-quarter percentage change based on the current and previous revenue values.
-- Ensure the results are ordered by quarter_number to maintain the correct sequence.    
WITH quarterly_revenue AS (
    SELECT
        quarter_number,
        ROUND(SUM(quantity * (vehicle_price - ((discount/100)*vehicle_price))), 0) AS total_revenue_per_quarter
    FROM 
        gl_project.order_t
    GROUP BY 
        quarter_number
    ORDER BY 
        quarter_number ASC
),
revenue_with_lag AS (
    SELECT
        quarter_number,
        total_revenue_per_quarter,
        LAG(total_revenue_per_quarter, 1) OVER (ORDER BY quarter_number ASC) AS prev_quarter_revenue
    FROM 
        quarterly_revenue
),
overall_net_revenue AS (
    SELECT 
        ROUND(SUM(quantity * (vehicle_price - ((discount/100)*vehicle_price))), 0) AS overall_net_revenue
    FROM 
        gl_project.order_t
)
SELECT
    rw.quarter_number,
    rw.total_revenue_per_quarter,
    rw.prev_quarter_revenue,
    CASE 
        WHEN rw.prev_quarter_revenue IS NOT NULL THEN 
            (rw.total_revenue_per_quarter - rw.prev_quarter_revenue) / rw.prev_quarter_revenue * 100
        ELSE 
            0.0
    END AS quarter_percentage_change,
    onr.overall_net_revenue
FROM 
    revenue_with_lag rw
    INNER JOIN overall_net_revenue onr ON 1=1
ORDER BY 
    rw.quarter_number ASC;
    
-- Question 8:
-- What is the trend of net revenue and orders by quarters? [4 marks]
-- Hint: Find out the sum of net revenue and count the number of orders for each quarter.
SELECT
    quarter_number,
    ROUND(SUM(quantity * (vehicle_price - ((discount/100)*vehicle_price))), 0) AS total_net_revenue,
    COUNT(order_id) AS total_orders
FROM 
    gl_project.order_t
GROUP BY 
    quarter_number
ORDER BY 
    quarter_number ASC;

-- Question 9:
-- What is the average discount offered for different types of credit cards? [3 marks]
-- Hint: Find out the average of discount for each credit card type.    
SELECT 
    C.credit_card_type,
    AVG(O.discount) AS avg_discount
FROM 
    gl_project.customer_t C
INNER JOIN 
    gl_project.order_t O
ON 
    C.customer_id = O.customer_id
GROUP BY 
    C.credit_card_type
ORDER BY 
    avg_discount DESC;

-- Question 10:
-- What is the average time taken to ship the placed orders for each quarter? [3 marks]

SELECT 
    quarter_number,
    AVG(DATEDIFF(ship_date, order_date)) AS avg_days_for_shipping
FROM 
    gl_project.order_t
GROUP BY 
    quarter_number
ORDER BY 
    quarter_number ASC;
    
    select avg(average_shipping_time) from(SELECT 
	quarter_number,
   AVG(DATEDIFF(ship_date, order_date)) AS average_shipping_time
FROM gl_project.order_t
GROUP BY 1
ORDER BY 1)a;
    
SELECT 
    AVG(DATEDIFF(ship_date, order_date)) AS avg_days_for_shipping_overall
FROM 
    gl_project.order_t;
SELECT 
    count(DATEDIFF(ship_date, order_date)) AS avg_days_for_shipping
FROM 
    gl_project.order_t;


SELECT 
    ROUND(
        SUM(quantity * (vehicle_price - ((discount / 100) * vehicle_price))), 
        0
    ) AS total_net_revenue
FROM 
    gl_project.order_t;


