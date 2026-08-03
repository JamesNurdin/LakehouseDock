WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        d.d_year,
        CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
    FROM tpcds.customer c
    JOIN tpcds.store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE c.c_first_sales_date_sk = 2450511
      AND d.d_year = 2002
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.d_year,
    cs.purchase_type,
    SUM(cs.ss_net_profit) AS total_net_profit,
    COUNT(*) AS purchase_count,
    AVG(cs.ss_quantity) AS avg_quantity,
    (
        SELECT COUNT(*)
        FROM tpcds.web_returns wr
        WHERE wr.wr_returning_customer_sk = cs.c_customer_sk
          AND wr.wr_return_tax > 100
    ) AS high_tax_return_cnt,
    lr.total_return_loss
FROM customer_sales cs
JOIN LATERAL (
    SELECT SUM(wr.wr_net_loss) AS total_return_loss
    FROM tpcds.web_returns wr
    WHERE wr.wr_returning_customer_sk = cs.c_customer_sk
      AND wr.wr_returned_date_sk = cs.ss_sold_date_sk
) lr ON TRUE
WHERE cs.purchase_type = 'Bulk'
GROUP BY
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.d_year,
    cs.purchase_type,
    lr.total_return_loss
HAVING SUM(cs.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
