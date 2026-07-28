WITH catalog_sales_agg AS (
  SELECT
    i.i_category AS product_category,
    sm.sm_type AS ship_type,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    CASE
      WHEN SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_quantity), 0) > 10 THEN 'High Discount'
      ELSE 'Low Discount'
    END AS discount_level
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE td.t_second < 5
  GROUP BY i.i_category, sm.sm_type
),
web_sales_agg AS (
  SELECT
    i.i_category AS product_category,
    sm.sm_type AS ship_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    CASE
      WHEN SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_quantity), 0) > 10 THEN 'High Discount'
      ELSE 'Low Discount'
    END AS discount_level
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE td.t_second < 5
  GROUP BY i.i_category, sm.sm_type
)
SELECT
  product_category,
  ship_type,
  total_sales,
  total_discount,
  total_quantity,
  discount_level
FROM catalog_sales_agg
UNION ALL
SELECT
  product_category,
  ship_type,
  total_sales,
  total_discount,
  total_quantity,
  discount_level
FROM web_sales_agg
ORDER BY total_sales DESC
LIMIT 100
