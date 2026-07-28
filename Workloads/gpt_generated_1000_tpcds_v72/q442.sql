WITH agg AS (
  SELECT
    s.s_state,
    c.c_birth_year,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(sr.sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    CASE WHEN SUM(sr.sr_return_amt) > 0 THEN 'Has Return' ELSE 'No Return' END AS return_flag
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE s.s_zip = '79532'
    AND ca.ca_state = 'CA'
    AND ws.ws_list_price > 50
    AND sr.sr_reversed_charge < 100
  GROUP BY ROLLUP (s.s_state, c.c_birth_year)
)
SELECT
  agg.s_state,
  agg.c_birth_year,
  agg.total_net_paid,
  agg.total_return_amt,
  agg.distinct_orders,
  agg.return_flag,
  ROW_NUMBER() OVER (PARTITION BY agg.s_state ORDER BY agg.total_net_paid DESC) AS state_rank,
  (SELECT AVG(sr_inner.sr_return_amt) FROM store_returns sr_inner WHERE sr_inner.sr_reversed_charge < 100) AS overall_avg_return
FROM agg
WHERE agg.s_state IS NOT NULL
ORDER BY agg.s_state, state_rank
LIMIT 100
