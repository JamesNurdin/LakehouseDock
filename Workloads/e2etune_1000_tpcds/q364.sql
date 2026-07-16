SELECT
  d.d_year,
  d.d_month_seq,
  d.d_week_seq,
  SUM(i.inv_quantity_on_hand) AS total_qty,
  AVG(i.inv_quantity_on_hand) AS avg_qty,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
  (
    SELECT COUNT(*)
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = 'HIGH'
      AND ib.ib_lower_bound >= 50000
  ) AS high_income_households,
  RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS qty_rank
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND d.d_month_seq BETWEEN 1 AND 12
  AND d.d_week_seq BETWEEN 1 AND 52
GROUP BY d.d_year, d.d_month_seq, d.d_week_seq
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY d.d_year, qty_rank
LIMIT 50
