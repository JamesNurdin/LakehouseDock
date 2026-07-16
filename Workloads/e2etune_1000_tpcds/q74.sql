WITH store_return_agg AS (
    SELECT sr.sr_store_sk,
           COUNT(*) AS return_cnt,
           SUM(sr.sr_return_amt) AS total_return_amt,
           SUM(sr.sr_net_loss) AS total_net_loss,
           AVG(sr.sr_return_quantity) AS avg_return_qty,
           COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451000 AND 2452000
      AND sr.sr_return_amt > 0
    GROUP BY sr.sr_store_sk
)
SELECT s.s_state,
       s.s_city,
       s.s_store_name,
       a.return_cnt,
       a.total_return_amt,
       a.total_net_loss,
       a.avg_return_qty,
       a.distinct_customers,
       ROUND(a.total_return_amt / NULLIF(a.return_cnt, 0), 2) AS avg_return_per_txn,
       RANK() OVER (PARTITION BY s.s_state ORDER BY a.total_return_amt DESC) AS state_return_rank
FROM store_return_agg a
JOIN store s ON a.sr_store_sk = s.s_store_sk
WHERE s.s_tax_percentage >= 0.05
  AND s.s_closed_date_sk IS NULL
  AND s.s_geography_class = 'Unknown'
GROUP BY s.s_state, s.s_city, s.s_store_name, a.return_cnt, a.total_return_amt, a.total_net_loss, a.avg_return_qty, a.distinct_customers
HAVING a.total_return_amt > 5000
ORDER BY a.total_return_amt DESC
LIMIT 100
