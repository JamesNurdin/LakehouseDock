/* Goal: Combine catalog sales and store return transactions, deduplicate them, and compute distinct customer counts and distinct revenue totals per preferred-customer flag, while keeping only customers that have at least one store return over $50. */
WITH sales AS (
    SELECT
        cs.cs_order_number                               AS transaction_id,
        c.c_customer_sk                                 AS customer_sk,
        c.c_preferred_cust_flag                         AS preferred_flag,
        cs.cs_sold_date_sk                              AS date_sk,
        cs.cs_ext_sales_price                           AS revenue,
        cs.cs_quantity                                  AS quantity,
        hd.hd_income_band_sk                            AS income_band_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND cs.cs_ext_sales_price > 0
),
returns AS (
    SELECT
        sr.sr_ticket_number                             AS transaction_id,
        c.c_customer_sk                                 AS customer_sk,
        c.c_preferred_cust_flag                         AS preferred_flag,
        sr.sr_returned_date_sk                          AS date_sk,
        -sr.sr_return_amt                               AS revenue,
        sr.sr_return_quantity                           AS quantity,
        hd.hd_income_band_sk                            AS income_band_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND sr.sr_return_amt > 0
),
union_transactions AS (
    SELECT transaction_id, customer_sk, preferred_flag, date_sk, revenue, quantity, income_band_sk
    FROM sales
    UNION
    SELECT transaction_id, customer_sk, preferred_flag, date_sk, revenue, quantity, income_band_sk
    FROM returns
)
SELECT
    u.preferred_flag,
    COUNT(DISTINCT u.customer_sk)      AS distinct_customers,
    SUM(DISTINCT u.revenue)            AS sum_distinct_revenue,
    COUNT(DISTINCT u.transaction_id)   AS distinct_transactions,
    AVG(u.quantity)                    AS avg_quantity
FROM union_transactions u
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_customer_sk = u.customer_sk
      AND sr.sr_return_amt > 50
)
GROUP BY u.preferred_flag
ORDER BY distinct_customers DESC
LIMIT 100
