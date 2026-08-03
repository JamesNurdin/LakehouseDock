WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_promo_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 2
      AND cs_ext_sales_price > 0
    GROUP BY cs_call_center_sk, cs_ship_mode_sk, cs_promo_sk, cs_sold_time_sk
)
SELECT
    cc.cc_call_center_id,
    sm.sm_ship_mode_id,
    p.p_promo_name,
    td.t_hour,
    SUM(sa.total_sales) AS total_sales,
    AVG(sa.total_sales) AS avg_sales,
    COUNT(*) AS txn_count,
    COUNT(DISTINCT sa.cs_call_center_sk) AS distinct_call_centers,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    MIN(sa.total_sales) AS min_sales,
    MAX(sa.total_sales) AS max_sales,
    CASE WHEN sm.sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_category,
    (
        SELECT AVG(cs_ext_sales_price)
        FROM catalog_sales
        WHERE cs_quantity > 0
    ) AS overall_avg_price
FROM sales_agg sa
JOIN call_center cc
  ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON sa.cs_promo_sk = p.p_promo_sk
JOIN time_dim td
  ON sa.cs_sold_time_sk = td.t_time_sk
WHERE cc.cc_division_name = 'able'
  AND cc.cc_sq_ft > 500000000
  AND sm.sm_code = 'AIR'
  AND p.p_discount_active = 'Y'
  AND td.t_hour IN (10, 16)
  AND td.t_sub_shift = 'morning'
GROUP BY
    cc.cc_call_center_id,
    sm.sm_ship_mode_id,
    p.p_promo_name,
    td.t_hour,
    sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
