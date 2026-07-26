WITH store_cust AS (
    SELECT DISTINCT sr.sr_store_sk AS store_sk, sr.sr_customer_sk AS customer_sk
    FROM store_returns sr
),
sales_per_store AS (
    SELECT sc.store_sk,
           SUM(cs.cs_net_profit) AS total_sales_profit,
           COUNT(cs.cs_order_number) AS total_sales_orders
    FROM store_cust sc
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = sc.customer_sk
    JOIN customer c ON c.c_customer_sk = sc.customer_sk
    GROUP BY sc.store_sk
),
returns_per_store AS (
    SELECT sr.sr_store_sk AS store_sk,
           SUM(sr.sr_net_loss) AS total_return_loss,
           SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(sr.sr_ticket_number) AS total_returns
    FROM store_returns sr
    GROUP BY sr.sr_store_sk
)
SELECT s.s_store_id,
       s.s_store_name,
       COALESCE(sp.total_sales_profit, 0) AS sales_profit,
       COALESCE(rp.total_return_loss, 0) AS return_loss,
       CASE
           WHEN COALESCE(sp.total_sales_profit,0) = 0 THEN 0
           ELSE ROUND((COALESCE(rp.total_return_loss,0) / COALESCE(sp.total_sales_profit,0)) * 100, 2)
       END AS return_loss_pct,
       CASE
           WHEN COALESCE(rp.total_return_loss,0) > 50000 THEN 'High Risk'
           WHEN COALESCE(rp.total_return_loss,0) > 20000 THEN 'Medium Risk'
           ELSE 'Low Risk'
       END AS risk_category,
       DENSE_RANK() OVER (ORDER BY COALESCE(rp.total_return_loss,0) DESC) AS loss_rank
FROM store s
LEFT JOIN sales_per_store sp ON sp.store_sk = s.s_store_sk
LEFT JOIN returns_per_store rp ON rp.store_sk = s.s_store_sk
ORDER BY loss_rank
LIMIT 50
