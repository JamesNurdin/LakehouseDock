WITH ticket_sales AS (
  SELECT ss_store_sk,
         ss_ticket_number,
         SUM(ss.ss_net_paid_inc_tax) AS sales_amount
  FROM store_sales ss
  GROUP BY ss_store_sk, ss_ticket_number
),
 ticket_returns AS (
  SELECT sr_store_sk,
         sr_ticket_number,
         SUM(sr.sr_return_amt_inc_tax) AS returns_amount
  FROM store_returns sr
  GROUP BY sr_store_sk, sr_ticket_number
)
SELECT s.s_store_id,
       ts.ss_ticket_number,
       ts.sales_amount,
       COALESCE(tr.returns_amount, 0) AS returns_amount,
       ts.sales_amount - COALESCE(tr.returns_amount, 0) AS net_ticket_revenue,
       CASE 
         WHEN ts.sales_amount - COALESCE(tr.returns_amount, 0) < 0 THEN 'Negative Revenue'
         ELSE 'Positive Revenue'
       END AS revenue_flag,
       SUM(ts.sales_amount - COALESCE(tr.returns_amount, 0)) OVER (PARTITION BY s.s_store_sk ORDER BY ts.ss_ticket_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_revenue
FROM store s
JOIN ticket_sales ts ON s.s_store_sk = ts.ss_store_sk
LEFT JOIN ticket_returns tr
  ON s.s_store_sk = tr.sr_store_sk
 AND ts.ss_ticket_number = tr.sr_ticket_number
ORDER BY s.s_store_id, ts.ss_ticket_number
