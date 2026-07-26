WITH store_cust AS (
    SELECT DISTINCT sr.sr_store_sk AS store_sk, sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0
),
sales_per_store AS (
    SELECT sc.store_sk,
           SUM(cs.cs_net_profit) AS total_sales_profit,
           COUNT(DISTINCT cs.cs_order_number) AS total_sales_orders,
           AVG(cs.cs_quantity) AS avg_quantity_per_order
    FROM store_cust sc
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = sc.customer_sk
    GROUP BY sc.store_sk
),
returns_per_store AS (
    SELECT sr.sr_store_sk AS store_sk,
           SUM(sr.sr_net_loss) AS total_return_loss,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(sr.sr_ticket_number) AS total_returns,
           MAX(sr.sr_return_amt) AS max_return_amount
    FROM store_returns sr
    GROUP BY sr.sr_store_sk
)
SELECT s.s_store_id,
       s.s_store_name,
       COALESCE(sp.total_sales_profit, 0) AS sales_profit,
       COALESCE(rp.total_return_loss, 0) AS return_loss,
       ROUND(COALESCE(rp.total_return_loss,0) / NULLIF(COALESCE(sp.total_sales_profit,0),0) * 100, 2) AS return_loss_pct,
       CASE
           WHEN COALESCE(rp.total_return_loss,0) > 75000 THEN 'Very High Risk'
           WHEN COALESCE(rp.total_return_loss,0) > 30000 THEN 'High Risk'
           ELSE 'Low Risk'
       END AS risk_category,
       DENSE_RANK() OVER (ORDER BY COALESCE(rp.total_return_loss,0) DESC) AS loss_rank,
       sp.avg_quantity_per_order
FROM store s
LEFT JOIN sales_per_store sp ON sp.store_sk = s.s_store_sk
LEFT JOIN returns_per_store rp ON rp.store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
ORDER BY loss_rank, s.s_store_id
LIMIT 25
