WITH
  sales_sampled AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  joined_main AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cc.cc_gmt_offset,
      cc.cc_rec_end_date,
      w.w_warehouse_sq_ft,
      w.w_city,
      p.p_channel_catalog,
      p.p_discount_active
    FROM sales_sampled cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_gmt_offset IN (-8.00, -5.00, -6.00)
      AND cc.cc_rec_end_date = DATE '2000-12-31'
      AND w.w_warehouse_sq_ft > 500000
      AND w.w_city LIKE 'A%'
      AND p.p_channel_catalog = 'Y'
      AND p.p_discount_active = 'Y'
  ),
  order_agg_main AS (
    SELECT
      cs_order_number,
      cc_gmt_offset,
      w_city,
      p_discount_active,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_net_profit) AS total_profit
    FROM joined_main
    GROUP BY ROLLUP (cs_order_number, cc_gmt_offset, w_city, p_discount_active)
  ),
  joined_alt AS (
    SELECT
      cs.cs_order_number,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cc.cc_gmt_offset,
      cc.cc_rec_end_date,
      w.w_warehouse_sq_ft,
      w.w_city,
      p.p_channel_catalog,
      p.p_discount_active
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    FULL OUTER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    FULL OUTER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_gmt_offset = -7.00
      AND cc.cc_rec_end_date = DATE '2001-12-31'
      AND w.w_warehouse_sq_ft < 800000
      AND w.w_city LIKE '%town'
      AND p.p_channel_catalog = 'N'
      AND p.p_discount_active = 'N'
  ),
  order_agg_alt AS (
    SELECT
      cs_order_number,
      cc_gmt_offset,
      w_city,
      p_discount_active,
      SUM(cs_ext_sales_price) AS total_sales,
      SUM(cs_net_profit) AS total_profit
    FROM joined_alt
    GROUP BY ROLLUP (cs_order_number, cc_gmt_offset, w_city, p_discount_active)
  ),
  union_agg AS (
    SELECT * FROM order_agg_main
    UNION
    SELECT * FROM order_agg_alt
  ),
  final AS (
    SELECT
      cs_order_number,
      cc_gmt_offset,
      w_city,
      p_discount_active,
      total_sales,
      total_profit,
      SUM(total_sales) OVER (PARTITION BY cc_gmt_offset) AS sales_by_offset,
      RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM union_agg
    WHERE total_sales IS NOT NULL
  )
SELECT
  cs_order_number,
  cc_gmt_offset,
  w_city,
  p_discount_active,
  total_sales,
  total_profit,
  sales_by_offset,
  sales_rank
FROM final
WHERE total_profit > (SELECT AVG(total_profit) FROM union_agg)
ORDER BY sales_rank
LIMIT 100
