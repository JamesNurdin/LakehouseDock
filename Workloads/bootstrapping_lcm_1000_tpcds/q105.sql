WITH returns_with_quarter AS (
  SELECT
    cr.*,
    dd.d_year,
    dd.d_month_seq,
    CASE
      WHEN dd.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
      WHEN dd.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
      WHEN dd.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
      ELSE 'Q4'
    END AS quarter,
    sm.sm_type,
    s.s_state,
    inv.inv_quantity_on_hand
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN inventory inv ON inv.inv_date_sk = dd.d_date_sk
  JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
  WHERE dd.d_year >= 2000
)
SELECT
  d_year,
  quarter,
  sm_type,
  s_state,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(inv_quantity_on_hand) AS total_inventory_qty,
  SUM(cr_return_amount) / NULLIF(SUM(inv_quantity_on_hand), 0) AS return_to_inventory_ratio,
  AVG(cr_net_loss) AS avg_net_loss,
  COUNT(*) AS return_cnt,
  SUM(CASE WHEN cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_value_returns
FROM returns_with_quarter
GROUP BY
  d_year,
  quarter,
  sm_type,
  s_state
HAVING SUM(cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
