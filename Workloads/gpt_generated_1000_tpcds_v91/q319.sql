WITH cs AS (
  SELECT
    cs_order_number,
    cs_sold_time_sk,
    cs_ship_mode_sk,
    cs_catalog_page_sk,
    cs_ext_sales_price,
    cs_quantity
  FROM catalog_sales
  WHERE cs_quantity > 0
),
cp AS (
  SELECT
    cp_catalog_page_sk,
    cp_type,
    cp_description
  FROM catalog_page
  WHERE cp_type LIKE '%SPECIAL%' OR regexp_like(cp_description, '(?i)discount|sale')
)
SELECT
  sm.sm_type AS ship_mode_type,
  CASE
    WHEN regexp_like(cp.cp_description, '(?i)discount|sale') THEN 'Discount'
    ELSE 'Other'
  END AS description_category,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_quantity) AS avg_quantity,
  COALESCE(substr(cp.cp_type, 1, 5), 'N/A') AS page_type_prefix
FROM
  cs
  FULL OUTER JOIN cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
GROUP BY
  sm.sm_type,
  CASE
    WHEN regexp_like(cp.cp_description, '(?i)discount|sale') THEN 'Discount'
    ELSE 'Other'
  END,
  COALESCE(substr(cp.cp_type, 1, 5), 'N/A')
ORDER BY
  total_sales DESC,
  ship_mode_type
LIMIT 100
