WITH agg AS (
  SELECT
    s.s_state,
    d.d_year,
    s.s_store_name,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(*) AS return_cnt,
    CASE
      WHEN SUM(sr.sr_return_amt) > 10000 THEN 'HIGH'
      WHEN SUM(sr.sr_return_amt) > 5000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS return_category
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND s.s_state IN ('CA', 'TX', 'NY')
    AND cd.cd_marital_status IN ('M', 'S')
  GROUP BY ROLLUP (s.s_state, d.d_year, s.s_store_name)
),
max_year AS (
  SELECT d_year, MAX(total_return_amt) AS max_return_amt
  FROM agg
  GROUP BY d_year
)
SELECT
  a.s_state,
  a.d_year,
  a.s_store_name,
  a.total_return_amt,
  a.total_return_qty,
  a.total_inventory_on_hand,
  a.return_category,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_return_amt DESC) AS return_rank,
  CASE WHEN a.total_return_amt = m.max_return_amt THEN 1 ELSE 0 END AS is_top_store
FROM agg a
JOIN max_year m ON a.d_year = m.d_year
WHERE a.s_state IS NOT NULL  -- exclude grand total rows from rollup
ORDER BY a.d_year DESC, return_rank
LIMIT 100
