WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_wholesale_cost < 80
      AND c.c_birth_month IN (6, 12)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month
),
customer_returns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_store_credit) AS total_store_credit,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451000 AND 2452000
      AND sr.sr_store_credit > 0
    GROUP BY sr.sr_customer_sk
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.c_birth_month,
    cs.total_sales,
    cr.total_return_loss,
    (cs.total_sales - COALESCE(cr.total_return_loss, 0)) AS net_sales_after_returns,
    CASE
        WHEN (cs.total_profit - COALESCE(cr.total_return_loss, 0)) > 10000 THEN 'High Profit'
        WHEN (cs.total_profit - COALESCE(cr.total_return_loss, 0)) BETWEEN 0 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY (cs.total_sales - COALESCE(cr.total_return_loss, 0)) DESC) AS sales_rank
FROM customer_sales cs
LEFT JOIN customer_returns cr
    ON cs.c_customer_sk = cr.sr_customer_sk
ORDER BY sales_rank
LIMIT 100
