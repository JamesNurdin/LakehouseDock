WITH sales_agg AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_net_profit,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
),
returns_agg AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(*) AS return_cnt,
           MIN(s.s_store_name) AS store_name
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY sr.sr_customer_sk
)
SELECT c.c_customer_id,
       COALESCE(s.total_net_paid, 0) AS total_sales_amount,
       COALESCE(s.total_net_profit, 0) AS total_sales_profit,
       COALESCE(r.total_net_loss, 0) AS total_returns_loss,
       (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS net_balance,
       CASE
           WHEN (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 10000 THEN 'Platinum'
           WHEN (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 5000 THEN 'Gold'
           WHEN (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 1000 THEN 'Silver'
           ELSE 'Bronze'
       END AS profit_tier,
       r.store_name,
       RANK() OVER (ORDER BY (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank
FROM customer c
LEFT JOIN sales_agg s ON s.customer_sk = c.c_customer_sk
LEFT JOIN returns_agg r ON r.customer_sk = c.c_customer_sk
WHERE COALESCE(s.sales_cnt,0) + COALESCE(r.return_cnt,0) > 0
ORDER BY profit_rank
LIMIT 100
