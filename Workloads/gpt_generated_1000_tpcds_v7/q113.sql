WITH catalog_part AS (
  SELECT i.i_item_id,
         i.i_product_name,
         SUM(cs.cs_net_paid) AS total_sales,
         'catalog' AS channel
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cc.cc_state = 'CA'
    AND w.w_gmt_offset = -6.00
    AND i.i_rec_start_date > DATE '1999-01-01'
  GROUP BY i.i_item_id, i.i_product_name
),
web_part AS (
  SELECT i.i_item_id,
         i.i_product_name,
         SUM(ws.ws_net_paid) AS total_sales,
         'web' AS channel
  FROM web_sales ws
  JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE s.web_state = 'CA'
    AND w.w_gmt_offset = -6.00
    AND i.i_rec_start_date > DATE '1999-01-01'
  GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM catalog_part
UNION ALL
SELECT *
FROM web_part
LIMIT 100
