WITH sales_no_return AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    i.i_item_id,
    i.i_item_desc,
    i.i_category,
    w.w_warehouse_name,
    cc.cc_name
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE regexp_like(i.i_item_desc, '\\d{2,}')
    AND w.w_warehouse_name LIKE '%Warehouse%'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
    )
)
SELECT
  s.i_category,
  s.i_item_id,
  s.i_item_desc,
  s.w_warehouse_name,
  s.cc_name,
  SUM(s.cs_quantity) AS total_qty,
  SUM(s.cs_net_paid) AS total_net_paid,
  AVG(s.cs_net_profit) AS avg_profit,
  CASE
    WHEN SUM(s.cs_net_paid) > 100000 THEN 'High'
    WHEN SUM(s.cs_net_paid) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_tier,
  ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY SUM(s.cs_net_paid) DESC) AS category_rank,
  CONCAT(s.i_item_id, '-', SUBSTRING(s.i_item_desc, 1, 10)) AS item_key,
  regexp_extract(s.i_item_desc, '(\\d+)', 1) AS extracted_number
FROM sales_no_return s
GROUP BY
  s.i_category,
  s.i_item_id,
  s.i_item_desc,
  s.w_warehouse_name,
  s.cc_name,
  regexp_extract(s.i_item_desc, '(\\d+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
