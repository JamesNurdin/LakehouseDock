WITH sales_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    REGEXP_EXTRACT(i.i_product_name, '(\\d+)', 1) AS product_number,
    td.t_shift,
    CONCAT(i.i_product_name, ' - ', td.t_shift) AS product_shift_label,
    'sales' AS metric_type,
    SUM(cs.cs_ext_sales_price) AS metric_value,
    CASE
      WHEN SUM(cs.cs_ext_discount_amt) > 0.1 * SUM(cs.cs_ext_sales_price) THEN 'High Discount'
      ELSE 'Low Discount'
    END AS metric_category
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE REGEXP_LIKE(i.i_product_name, '\\d')
    AND i.i_product_name LIKE '%Pro%'
    AND p.p_channel_email = 'N'
    AND p.p_promo_name LIKE '%Discount%'
  GROUP BY i.i_item_id, i.i_product_name, REGEXP_EXTRACT(i.i_product_name, '(\\d+)', 1), td.t_shift, CONCAT(i.i_product_name, ' - ', td.t_shift)
),
returns_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    REGEXP_EXTRACT(i.i_product_name, '(\\d+)', 1) AS product_number,
    td.t_shift,
    CONCAT(i.i_product_name, ' - ', td.t_shift) AS product_shift_label,
    'returns' AS metric_type,
    SUM(sr.sr_return_amt) AS metric_value,
    CASE
      WHEN SUM(sr.sr_return_amt) > 0 THEN 'Has Return'
      ELSE 'No Return'
    END AS metric_category
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  WHERE REGEXP_LIKE(i.i_product_name, '\\d')
    AND i.i_product_name LIKE '%Pro%'
  GROUP BY i.i_item_id, i.i_product_name, REGEXP_EXTRACT(i.i_product_name, '(\\d+)', 1), td.t_shift, CONCAT(i.i_product_name, ' - ', td.t_shift)
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY product_shift_label, metric_type
LIMIT 100
