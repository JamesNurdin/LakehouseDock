WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        c_preferred_cust_flag
    FROM tpcds.customer
    WHERE c_birth_month IN (1, 2, 12)
      AND c_preferred_cust_flag = 'Y'
      AND c_birth_day IN (13, 26)
)

SELECT DISTINCT
    cust.c_customer_id,
    agg.role,
    agg.total_return_qty,
    agg.total_return_amt_inc_tax,
    agg.total_net_loss
FROM (
    SELECT
        c.c_customer_id,
        'refunded' AS role,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM filtered_customers c
    JOIN tpcds.web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt_inc_tax >= 200
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY c.c_customer_id

    UNION ALL

    SELECT
        c.c_customer_id,
        'returning' AS role,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM filtered_customers c
    JOIN tpcds.web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE wr.wr_return_amt_inc_tax >= 200
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY c.c_customer_id
) AS agg
JOIN filtered_customers cust
    ON cust.c_customer_id = agg.c_customer_id
ORDER BY agg.total_net_loss DESC
LIMIT 100
