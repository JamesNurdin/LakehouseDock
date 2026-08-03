WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_ship_date_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_wholesale_cost,
    cs.cs_ext_discount_amt,
    cp.cp_catalog_page_id,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    p.p_discount_active,
    sm.sm_type,
    d_sold.d_year,
    d_sold.d_qoy,
    wp.wp_max_ad_count,
    wp.wp_url,
    ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS metrics_arr
  FROM catalog_sales cs
  FULL OUTER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
  JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2001
    AND d_sold.d_qoy = 3
    AND i.i_brand = 'Brand#45'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND wp.wp_max_ad_count >= 2
    AND cs.cs_wholesale_cost > (
          SELECT MIN(cs2.cs_wholesale_cost)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = 2452000
        )
    AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_purpose = 'Unknown'
        )
)
SELECT
  base.d_year,
  base.i_category,
  base.sm_type,
  COUNT(*) AS order_count,
  SUM(base.cs_ext_sales_price) AS total_sales,
  AVG(base.cs_net_profit) AS avg_profit,
  MIN(base.cs_ext_discount_amt) AS min_discount,
  MAX(base.cs_wholesale_cost) AS max_wholesale_cost,
  metric_val AS metric_value
FROM base
CROSS JOIN UNNEST(base.metrics_arr) AS t(metric_val)
GROUP BY base.d_year, base.i_category, base.sm_type, metric_val
ORDER BY total_sales DESC, order_count DESC
LIMIT 100
