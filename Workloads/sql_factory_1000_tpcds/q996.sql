WITH sales_agg AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_net_profit,
           SUM(cs.cs_quantity) AS total_quantity,
           COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    WHERE cs.cs_ship_mode_sk IN (1,2,3)
    GROUP BY cs.cs_bill_customer_sk
),
returns_agg AS (
    SELECT sr.sr_customer_sk AS customer_sk,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(*) AS return_cnt,
           MIN(s.s_state) AS return_state
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_tax_percentage > 0.05
    GROUP BY sr.sr_customer_sk
)
SELECT c.c_customer_id,
       COALESCE(s.total_net_paid, 0) AS total_sales_amount,
       COALESCE(s.total_quantity, 0) AS total_quantity_sold,
       COALESCE(r.total_return_amount, 0) AS total_return_amount,
       (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS net_balance,
       CASE
           WHEN (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 15000 THEN 'Platinum'
           WHEN (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 8000 THEN 'Gold'
           WHEN (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) >= 3000 THEN 'Silver'
           ELSE 'Bronze'
       END AS profit_tier,
       r.return_state,
       RANK() OVER (ORDER BY (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank,
       SUM(COALESCE(s.total_quantity,0)) OVER (PARTITION BY c.c_customer_id) AS cumulative_quantity
FROM customer c
LEFT JOIN sales_agg s ON s.customer_sk = c.c_customer_sk
LEFT JOIN returns_agg r ON r.customer_sk = c.c_customer_sk
WHERE COALESCE(s.distinct_items,0) > 0
ORDER BY profit_rank, c.c_customer_id
LIMIT 75
