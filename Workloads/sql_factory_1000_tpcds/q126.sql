WITH customer_first_returns AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d_sales.d_date AS first_sales_date,
        MIN(d_return.d_date) AS first_return_date,
        date_diff('day', d_sales.d_date, MIN(d_return.d_date)) AS days_to_first_return,
        cp_ret.cp_department AS return_department
    FROM customer c
    JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN catalog_page cp_ret ON d_return.d_date_sk BETWEEN cp_ret.cp_start_date_sk AND cp_ret.cp_end_date_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, d_sales.d_date, cp_ret.cp_department
    HAVING MIN(d_return.d_date) IS NOT NULL
),
ranked_customers AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY days_to_first_return) AS quartile
    FROM customer_first_returns
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    first_sales_date,
    first_return_date,
    days_to_first_return,
    return_department,
    quartile,
    CASE
        WHEN quartile = 1 THEN 'New'
        WHEN quartile = 2 THEN 'Mid'
        ELSE 'Loyal'
    END AS customer_tier
FROM ranked_customers
ORDER BY days_to_first_return
