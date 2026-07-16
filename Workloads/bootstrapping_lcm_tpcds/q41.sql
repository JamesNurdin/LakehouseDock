SELECT
  d.d_year,
  d.d_month_seq,
  CASE
    WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
    WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
    ELSE 'Other'
  END AS region,
  r.r_reason_desc,
  COUNT(*) AS return_count,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
  SUM(cr.cr_fee) AS total_fee,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2012 AND 2015
  AND i.inv_quantity_on_hand > 0
  AND r.r_reason_desc LIKE '%defect%'
GROUP BY
  d.d_year,
  d.d_month_seq,
  CASE
    WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West'
    WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'East'
    ELSE 'Other'
  END,
  r.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
