WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_ext_tax
    FROM catalog_sales cs
    WHERE cs.cs_coupon_amt > 0
      AND cs.cs_ext_tax BETWEEN 10 AND 100
      AND cs.cs_quantity >= 2
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    sm.sm_carrier,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    SUM(fs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT fs.cs_sold_date_sk) AS distinct_sale_days,
    CASE WHEN SUM(fs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_type ORDER BY SUM(fs.cs_net_paid) DESC) AS rn_type
FROM filtered_sales fs
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department = 'Electronics'
  AND sm.sm_carrier IN ('FEDEX', 'GERMA')
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = fs.cs_ship_mode_sk
          AND sm2.sm_code = 'AIR'
      )
GROUP BY cp.cp_catalog_page_id, cp.cp_type, sm.sm_carrier
HAVING SUM(fs.cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
