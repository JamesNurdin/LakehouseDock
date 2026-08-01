WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
    hd.hd_vehicle_count,
    SUM(ss.cs_ext_sales_price) AS total_ext_sales_price,
    AVG(ss.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ss.cs_item_sk) AS distinct_items_sold,
    MIN(ss.cs_sales_price) AS min_sales_price,
    MAX(ss.cs_sales_price) AS max_sales_price,
    lat.max_price_same_page
FROM sampled_sales ss
INNER JOIN catalog_page cp
    ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT OUTER JOIN household_demographics hd
    ON ss.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN LATERAL (
    SELECT MAX(cs2.cs_sales_price) AS max_price_same_page
    FROM catalog_sales cs2
    WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
) AS lat ON TRUE
WHERE cp.cp_department = 'Electronics'
  AND cp.cp_catalog_page_number IN (6, 14, 21)
  AND ss.cs_sales_price > 20
  AND ss.cs_quantity > 1
  AND (hd.hd_buy_potential = '5001-10000' OR hd.hd_buy_potential IS NULL)
  AND (hd.hd_vehicle_count >= 2 OR hd.hd_vehicle_count IS NULL)
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    COALESCE(hd.hd_buy_potential, 'Unknown'),
    hd.hd_vehicle_count,
    lat.max_price_same_page
ORDER BY total_ext_sales_price DESC
LIMIT 100
