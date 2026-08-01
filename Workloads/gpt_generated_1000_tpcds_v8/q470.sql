WITH joined_data AS (
  SELECT
    cc.cc_state,
    cc.cc_county,
    cc.cc_street_type,
    i.i_brand,
    i.i_brand_id,
    i.i_item_sk,
    td_cs.t_meal_time,
    cs.cs_ext_sales_price            AS catalog_sales_price,
    ss.ss_ext_sales_price            AS store_sales_price,
    cr.cr_return_amount               AS return_amount
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_returned_time_sk = td_cs.t_time_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cc.cc_county IN ('Bronx County', 'Dauphin County')
    AND cc.cc_street_type = 'Road'
    AND td_cs.t_meal_time IN ('lunch', 'dinner')
    AND i.i_brand IS NOT NULL
    AND cs.cs_sales_price > 20
    AND ss.ss_sales_price > 10
),
brand_totals AS (
  SELECT
    cc_state,
    i_brand,
    SUM(COALESCE(catalog_sales_price, 0) + COALESCE(store_sales_price, 0) - COALESCE(return_amount, 0)) AS total_sales,
    COUNT(DISTINCT i_item_sk)                                                      AS distinct_items_sold,
    MIN(i_item_sk)                                                               AS sample_item_sk
  FROM joined_data
  GROUP BY ROLLUP (cc_state, i_brand)
),
high_brands AS (
  SELECT i_brand FROM brand_totals WHERE total_sales > 500000
),
low_brands AS (
  SELECT i_brand FROM brand_totals WHERE total_sales < 100000
),
brand_intersection AS (
  SELECT i_brand FROM high_brands
  INTERSECT
  SELECT i_brand FROM low_brands
),
union_meals AS (
  SELECT cc_state, i_brand, 'lunch'  AS meal FROM joined_data WHERE t_meal_time = 'lunch'
  UNION ALL
  SELECT cc_state, i_brand, 'dinner' AS meal FROM joined_data WHERE t_meal_time = 'dinner'
),
filtered_brands AS (
  SELECT * FROM brand_totals WHERE i_brand IN (SELECT i_brand FROM brand_intersection)
),
final AS (
  SELECT
    bt.cc_state,
    bt.i_brand,
    bt.total_sales,
    bt.distinct_items_sold,
    RANK() OVER (PARTITION BY bt.cc_state ORDER BY bt.total_sales DESC) AS brand_rank,
    (SELECT SUM(cr2.cr_return_amount)
       FROM catalog_returns cr2
      WHERE cr2.cr_item_sk = bt.sample_item_sk)                         AS total_return_amount_for_item,
    CASE
      WHEN bt.total_sales > 200000 THEN 'High'
      WHEN bt.total_sales >  50000 THEN 'Medium'
      ELSE 'Low'
    END                                                                     AS sales_category
  FROM filtered_brands bt
  WHERE EXISTS (
          SELECT 1
            FROM catalog_returns cr3
           WHERE cr3.cr_item_sk = bt.sample_item_sk
             AND cr3.cr_return_amount > 0)
)
SELECT
  cc_state,
  i_brand,
  total_sales,
  distinct_items_sold,
  brand_rank,
  total_return_amount_for_item,
  sales_category
FROM final
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
