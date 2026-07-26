WITH sales_agg AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_paid) AS total_net_paid,
           MAX(cs.cs_net_profit) AS max_net_profit,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
    HAVING SUM(cs.cs_quantity) > 10
),
returns_agg AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_net_loss) AS total_net_loss,
           COUNT(*) AS return_cnt,
           MAX(s.s_store_name) FILTER (WHERE s.s_state = 'CA') AS ca_store_name
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY sr.sr_customer_sk
)
SELECT c.c_customer_id,
       COALESCE(s.total_net_paid, 0) AS total_sales_amount,
       COALESCE(s.max_net_profit, 0) AS max_sales_profit,
       COALESCE(r.total_net_loss, 0) AS total_returns_loss,
       (COALESCE(s.max_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS net_balance,
       CASE
           WHEN (COALESCE(s.max_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 20000 THEN 'Diamond'
           WHEN (COALESCE(s.max_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 10000 THEN 'Platinum'
           ELSE 'Standard'
       END AS profit_tier,
       r.ca_store_name,
       DENSE_RANK() OVER (ORDER BY (COALESCE(s.max_net_profit, 0) - COALESCE(r.total_net_loss, 0)) DESC) AS profit_dense_rank
FROM customer c
LEFT JOIN sales_agg s ON s.customer_sk = c.c_customer_sk
LEFT JOIN returns_agg r ON r.customer_sk = c.c_customer_sk
WHERE COALESCE(s.sales_cnt,0) >= 2
ORDER BY profit_dense_rank
LIMIT 30
