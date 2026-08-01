/* Goal: Identify distinct customers who either spent more than $5,000 in catalog sales or returned more than $2,000 in store returns during a given date range, and show their total spent and total returned amounts. */
WITH raw_spenders AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.cs_net_paid_inc_ship_tax
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2452000
),
high_spenders AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        SUM(cs_net_paid_inc_ship_tax) AS total_spent,
        CAST(NULL AS decimal(7,2)) AS total_returned
    FROM raw_spenders
    GROUP BY c_customer_id, c_first_name, c_last_name
    HAVING SUM(cs_net_paid_inc_ship_tax) > 5000
),
raw_returns AS (
    SELECT DISTINCT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        sr.sr_return_amt_inc_tax
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2452000
),
high_returners AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        CAST(NULL AS decimal(7,2)) AS total_spent,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM raw_returns
    GROUP BY c_customer_id, c_first_name, c_last_name
    HAVING SUM(sr_return_amt_inc_tax) > 2000
),
combined AS (
    SELECT * FROM high_spenders
    UNION ALL
    SELECT * FROM high_returners
)
SELECT
    c_customer_id AS customer_id,
    c_first_name AS first_name,
    c_last_name AS last_name,
    SUM(total_spent) AS total_spent,
    SUM(total_returned) AS total_returned
FROM combined
GROUP BY c_customer_id, c_first_name, c_last_name
ORDER BY total_spent DESC, total_returned DESC
LIMIT 100
