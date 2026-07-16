SELECT cp.cp_type,
       ib.ib_upper_bound,
       COUNT(DISTINCT i.i_item_sk) AS distinct_items,
       AVG(i.i_current_price) AS avg_price,
       SUM(i.i_wholesale_cost) AS total_wholesale_cost
FROM catalog_page cp
JOIN income_band ib
  ON cp.cp_end_date_sk = ib.ib_income_band_sk
JOIN item i
  ON i.i_category_id = cp.cp_catalog_number
WHERE cp.cp_start_date_sk BETWEEN 2450000 AND 2452000
  AND i.i_rec_start_date >= DATE '2000-01-01'
GROUP BY cp.cp_type, ib.ib_upper_bound
HAVING COUNT(DISTINCT i.i_item_sk) > 5
ORDER BY total_wholesale_cost DESC
LIMIT 100
