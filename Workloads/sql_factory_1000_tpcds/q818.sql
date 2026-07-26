WITH daily_stats AS (
  SELECT 
    i.inv_item_sk,
    d.d_year,
    d.d_month_seq,
    d.d_date,
    i.inv_quantity_on_hand,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS daily_return_quantity,
    CASE 
      WHEN i.inv_quantity_on_hand = 0 THEN NULL
      ELSE CAST(COALESCE(SUM(cr.cr_return_quantity), 0) AS DOUBLE) / i.inv_quantity_on_hand
    END AS turnover_ratio
  FROM inventory i
  INNER JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr 
    ON cr.cr_returned_date_sk = d.d_date_sk 
   AND cr.cr_item_sk = i.inv_item_sk
  GROUP BY i.inv_item_sk, d.d_year, d.d_month_seq, d.d_date, i.inv_quantity_on_hand
),
monthly_turnover AS (
  SELECT 
    inv_item_sk,
    d_year,
    d_month_seq,
    SUM(daily_return_quantity) AS total_return_quantity,
    SUM(inv_quantity_on_hand) AS total_inventory_quantity,
    CASE 
      WHEN SUM(inv_quantity_on_hand) = 0 THEN NULL
      ELSE CAST(SUM(daily_return_quantity) AS DOUBLE) / SUM(inv_quantity_on_hand)
    END AS turnover_ratio
  FROM daily_stats
  GROUP BY inv_item_sk, d_year, d_month_seq
)
SELECT 
  inv_item_sk,
  d_year,
  d_month_seq,
  total_return_quantity,
  total_inventory_quantity,
  turnover_ratio,
  CASE 
    WHEN turnover_ratio > 0.5 THEN 'High'
    WHEN turnover_ratio > 0.2 THEN 'Medium'
    ELSE 'Low'
  END AS turnover_category,
  RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY turnover_ratio DESC) AS turnover_rank
FROM monthly_turnover
WHERE turnover_ratio IS NOT NULL
ORDER BY d_year, d_month_seq, turnover_rank
LIMIT 20
