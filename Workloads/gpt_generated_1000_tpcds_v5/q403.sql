WITH sales_enriched AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        ss.ss_wholesale_cost,
        d.d_day_name,
        d.d_year,
        c.c_preferred_cust_flag
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND c.c_preferred_cust_flag = 'Y'
      AND ss.ss_ext_tax > 10.00
)
SELECT
    se.d_day_name,
    COUNT(*) AS transaction_cnt,
    SUM(se.ss_net_profit) AS total_net_profit,
    AVG(se.ss_wholesale_cost) AS avg_wholesale_cost,
    CASE
        WHEN SUM(se.ss_net_profit) > 5000 THEN 'High'
        WHEN SUM(se.ss_net_profit) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_enriched se
GROUP BY se.d_day_name
ORDER BY total_net_profit DESC
LIMIT 100
