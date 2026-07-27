WITH sales_filtered AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    i.i_category,
    i.i_brand,
    i.i_item_desc,
    i.i_product_name,
    sm.sm_ship_mode_id,
    td.t_hour
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND regexp_like(i.i_item_desc, '(?i)elect')
    AND sm.sm_ship_mode_id LIKE '%AIR%'
)
SELECT
  CONCAT(s.i_brand, ' - ', s.i_category) AS brand_category,
  COUNT(*) AS sales_count,
  SUM(s.cs_net_profit) AS total_net_profit,
  AVG(s.cs_ext_discount_amt) AS avg_discount,
  MAX(s.cs_ext_sales_price) AS max_sales_price,
  REGEXP_EXTRACT(s.i_product_name, '([A-Z]{3}[0-9]{2})') AS extracted_code
FROM sales_filtered s
WHERE EXISTS (
  SELECT 1
  FROM store_returns sr
  JOIN time_dim tr ON sr.sr_return_time_sk = tr.t_time_sk
  WHERE sr.sr_item_sk = s.cs_item_sk
    AND sr.sr_reversed_charge > 10
    AND tr.t_hour BETWEEN 0 AND 23
)
GROUP BY
  CONCAT(s.i_brand, ' - ', s.i_category),
  REGEXP_EXTRACT(s.i_product_name, '([A-Z]{3}[0-9]{2})')
ORDER BY total_net_profit DESC
LIMIT 10
