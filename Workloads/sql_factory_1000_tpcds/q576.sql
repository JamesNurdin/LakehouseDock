WITH sales_per_customer AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
),
returns_per_customer_store AS (
    SELECT sr.sr_store_sk AS store_sk,
           sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_customer_sk
)
SELECT store_id,
       store_name,
       customer_id,
       first_name,
       last_name,
       sales_profit,
       return_loss,
       net_balance,
       customer_tier,
       customer_rank
FROM (
    SELECT s.s_store_id AS store_id,
           s.s_store_name AS store_name,
           c.c_customer_id AS customer_id,
           c.c_first_name AS first_name,
           c.c_last_name AS last_name,
           COALESCE(sp.sales_profit,0) AS sales_profit,
           COALESCE(rp.return_loss,0) AS return_loss,
           COALESCE(sp.sales_profit,0) - COALESCE(rp.return_loss,0) AS net_balance,
           CASE WHEN COALESCE(sp.sales_profit,0) - COALESCE(rp.return_loss,0) >= 5000 THEN 'VIP' ELSE 'Regular' END AS customer_tier,
           ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY COALESCE(sp.sales_profit,0) - COALESCE(rp.return_loss,0) DESC) AS customer_rank
    FROM store s
    JOIN returns_per_customer_store rp ON rp.store_sk = s.s_store_sk
    LEFT JOIN sales_per_customer sp ON sp.customer_sk = rp.customer_sk
    LEFT JOIN customer c ON c.c_customer_sk = rp.customer_sk
) t
WHERE t.customer_rank <= 5
ORDER BY t.store_id, t.customer_rank
