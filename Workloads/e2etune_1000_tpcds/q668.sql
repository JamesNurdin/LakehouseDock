SELECT
    cp.cp_department,
    ib.ib_income_band_sk,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(i.i_current_price) AS total_current_price,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    RANK() OVER (ORDER BY SUM(i.i_current_price) DESC) AS sales_rank
FROM catalog_page cp
JOIN item i
    ON cp.cp_start_date_sk = date_diff('day', DATE '1970-01-01', i.i_rec_start_date)
JOIN income_band ib
    ON i.i_wholesale_cost >= ib.ib_lower_bound
   AND i.i_wholesale_cost < ib.ib_upper_bound
WHERE cp.cp_type = 'monthly'
  AND cp.cp_catalog_number IN (1, 2, 3)
  AND i.i_current_price > 10
GROUP BY cp.cp_department, ib.ib_income_band_sk
HAVING COUNT(*) > 5
ORDER BY total_current_price DESC
LIMIT 100
