WITH store_agg AS (
  SELECT s.s_store_id,
         s.s_store_name,
         s.s_state,
         s.s_market_desc,
         sum(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
         sum(sr.sr_net_loss) AS total_net_loss,
         avg(sr.sr_return_quantity) AS avg_return_qty,
         count(DISTINCT c.c_customer_sk) AS unique_customers
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE c.c_birth_country IN ('ETHIOPIA', 'SEYCHELLES')
    AND c.c_current_cdemo_sk = 1473522
    AND s.s_state = 'CA'
  GROUP BY s.s_store_id, s.s_store_name, s.s_state, s.s_market_desc
  HAVING sum(sr.sr_return_amt_inc_tax) > 5000
)
SELECT s_store_id,
       s_store_name,
       s_state,
       s_market_desc,
       total_return_inc_tax,
       total_net_loss,
       avg_return_qty,
       unique_customers,
       RANK() OVER (ORDER BY total_net_loss DESC) AS store_rank
FROM store_agg
ORDER BY total_net_loss DESC
LIMIT 10
