WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_net_profit,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_ship_mode_sk,
    cs.cs_catalog_page_sk,
    cd.cd_gender,
    i.i_brand,
    i.i_size,
    i.i_manager_id,
    d.d_year,
    sm.sm_type,
    cp.cp_catalog_page_number,
    inv.inv_quantity_on_hand,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    ws.ws_quantity AS ws_quantity,
    ws.ws_sales_price AS ws_sales_price,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wp.wp_max_ad_count,
    wp.wp_web_page_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = i.i_item_sk
      AND cr.cr_returned_date_sk = d.d_date_sk
      AND cr.cr_returned_time_sk = t.t_time_sk
      AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
      AND ws.ws_sold_date_sk = d.d_date_sk
      AND ws.ws_sold_time_sk = t.t_time_sk
      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = i.i_item_sk
      AND wr.wr_returned_date_sk = d.d_date_sk
      AND wr.wr_returned_time_sk = t.t_time_sk
      AND wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE i.i_size = 'petite'
    AND i.i_manager_id = 19
    AND cp.cp_catalog_page_number = 13
    AND d.d_year = 2001
    AND sm.sm_type = 'AIR'
    AND wp.wp_max_ad_count = 0
),
color_expand AS (
  SELECT i_item_sk, color_elem
  FROM item
  CROSS JOIN UNNEST(ARRAY[i_color]) AS t(color_elem)
),
order_intersect AS (
  SELECT cs_order_number FROM catalog_sales cs WHERE cs.cs_quantity > 5
  INTERSECT
  SELECT ws_order_number FROM web_sales ws WHERE ws.ws_quantity > 5
),
year_set AS (
  SELECT 2000 AS yr UNION ALL SELECT 2001 UNION ALL SELECT 2002
)
SELECT
  d_year,
  i_brand,
  sm_type,
  COUNT(DISTINCT base.cs_order_number) AS distinct_orders,
  SUM(base.cs_quantity) AS total_quantity,
  AVG(base.cs_sales_price) AS avg_sales_price,
  SUM(base.cs_net_profit) AS total_net_profit,
  SUM(base.inv_quantity_on_hand) AS total_inventory,
  SUM(base.cr_return_amount) AS total_return_amount,
  SUM(base.ws_quantity) AS total_ws_quantity,
  SUM(base.wr_return_amt) AS total_wr_amount
FROM base
JOIN order_intersect oi ON base.cs_order_number = oi.cs_order_number
LEFT JOIN color_expand ce ON base.cs_item_sk = ce.i_item_sk
CROSS JOIN year_set ys
WHERE ys.yr = base.d_year
GROUP BY GROUPING SETS (
  (d_year, i_brand, sm_type),
  (d_year, i_brand),
  (d_year),
  ()
)
ORDER BY d_year, i_brand, sm_type
