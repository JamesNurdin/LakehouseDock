SELECT
    cp.cp_type,
    i.i_brand,
    ib.ib_upper_bound,
    COUNT(DISTINCT i.i_item_sk) AS distinct_item_cnt,
    SUM(i.i_current_price) AS total_current_price,
    AVG(i.i_current_price) AS avg_current_price,
    MIN(i.i_current_price) AS min_current_price,
    MAX(i.i_current_price) AS max_current_price
FROM catalog_page cp
JOIN item i
    ON i.i_brand_id = cp.cp_catalog_number
JOIN income_band ib
    ON ib.ib_income_band_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'
  AND i.i_current_price BETWEEN 5 AND 100
  AND cp.cp_start_date_sk >= 2450844
  AND cp.cp_end_date_sk <= 2451087
GROUP BY cp.cp_type, i.i_brand, ib.ib_upper_bound
HAVING COUNT(DISTINCT i.i_item_sk) > 10
ORDER BY total_current_price DESC
LIMIT 100
