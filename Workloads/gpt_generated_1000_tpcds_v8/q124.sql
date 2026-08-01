WITH sales_agg AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_category,
    sm.sm_ship_mode_id,
    SUM(cs.cs_ext_sales_price) AS total_ext_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    COUNT(*) AS order_cnt
  FROM catalog_sales cs
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_ext_list_price > 5000
    AND cs.cs_wholesale_cost BETWEEN 30 AND 80
    AND i.i_rec_start_date >= DATE '1999-01-01'
    AND sm.sm_code IN ('AIR', 'SEA')
  GROUP BY i.i_item_sk, i.i_item_id, i.i_category, sm.sm_ship_mode_id
),
full_join AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_ship_mode_sk,
    cs.cs_ext_sales_price,
    sm.sm_ship_mode_id,
    sm.sm_code
  FROM catalog_sales cs
  FULL OUTER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_ext_sales_price IS NOT NULL
)
SELECT
  fa.i_item_id,
  fa.i_category,
  fa.sm_ship_mode_id,
  fa.total_ext_sales,
  fa.total_quantity,
  fa.order_cnt,
  CASE WHEN fa.total_ext_sales >= 20000 THEN 'VIP' ELSE 'REG' END AS sales_tier,
  ROW_NUMBER() OVER (PARTITION BY fa.i_category ORDER BY fa.total_ext_sales DESC) AS category_rank,
  fj.sm_code
FROM sales_agg fa
LEFT JOIN full_join fj
  ON fa.i_item_sk = fj.cs_item_sk
  AND fa.sm_ship_mode_id = fj.sm_ship_mode_id
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs3
    WHERE cs3.cs_item_sk = fa.i_item_sk
      AND cs3.cs_net_profit < 0
)
  AND fa.total_quantity > 10
  AND fa.order_cnt >= 5
  AND fa.total_ext_sales BETWEEN 10000 AND 50000
ORDER BY fa.total_ext_sales DESC
LIMIT 100
