WITH store_cust AS (
    SELECT sr.sr_store_sk AS store_sk, sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt_inc_tax BETWEEN 10 AND 1000
),
sales_metrics AS (
    SELECT sc.store_sk,
           SUM(cs.cs_net_profit) AS profit_sum,
           COUNT(cs.cs_order_number) AS orders_cnt,
           SUM(cs.cs_quantity) AS total_quantity
    FROM store_cust sc
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = sc.customer_sk
    GROUP BY sc.store_sk
),
returns_metrics AS (
    SELECT sr.sr_store_sk AS store_sk,
           SUM(sr.sr_net_loss) AS loss_sum,
           COUNT(sr.sr_ticket_number) AS returns_cnt,
           AVG(sr.sr_return_amt_inc_tax) AS avg_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_store_sk
)
SELECT s.s_store_id,
       s.s_store_name,
       COALESCE(sm.profit_sum,0) AS total_profit,
       COALESCE(rm.loss_sum,0) AS total_loss,
       ROUND(COALESCE(rm.loss_sum,0) / NULLIF(COALESCE(sm.profit_sum,0),0) * 100,2) AS loss_percentage,
       CASE WHEN COALESCE(rm.loss_sum,0) > 40000 THEN 'Risky' ELSE 'Safe' END AS risk_flag,
       ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY COALESCE(rm.loss_sum,0) DESC) AS state_loss_rank,
       sm.total_quantity
FROM store s
LEFT JOIN sales_metrics sm ON sm.store_sk = s.s_store_sk
LEFT JOIN returns_metrics rm ON rm.store_sk = s.s_store_sk
ORDER BY state_loss_rank, s.s_store_name
LIMIT 35
