/*
  Goal: Identify top‑selling items per year, ranked by sales amount, while retaining all web sites even if they have no sales. The query joins all 12 selected TPC‑DS tables, applies multiple filters, samples inventory, intersects promotional and stocked items, uses GROUPING SETS for flexible aggregation, and ranks items with a window function.
*/
WITH
  -- Promotional items active in the year 2000
  promo_items AS (
    SELECT p.p_item_sk AS i_item_sk
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND p.p_discount_active = 'Y'
  ),
  -- Inventory items sampled and with stock on hand
  inventory_items AS (
    SELECT inv.inv_item_sk AS i_item_sk
    FROM inventory inv
      TABLESAMPLE BERNOULLI (5)
    WHERE inv.inv_quantity_on_hand > 0
  ),
  -- Items that are both promotional and in stock (intersection of key sets)
  common_items AS (
    SELECT i_item_sk FROM promo_items
    INTERSECT
    SELECT i_item_sk FROM inventory_items
  ),
  -- Rank items by total sales within each year
  sales_rank AS (
    SELECT
      ws.ws_item_sk,
      d.d_year,
      SUM(ws.ws_ext_sales_price) AS year_sales,
      RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_item_sk, d.d_year
  )
SELECT
  d.d_year,
  i.i_brand,
  w.w_warehouse_name,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  r.sales_rank
FROM web_sales ws
RIGHT OUTER JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp
  ON (cp.cp_start_date_sk = d.d_date_sk OR cp.cp_end_date_sk = d.d_date_sk)
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN sales_rank r
  ON r.ws_item_sk = ws.ws_item_sk
   AND r.d_year = d.d_year
WHERE cp.cp_type = 'monthly'
  AND w.w_warehouse_sq_ft > 500000
  AND i.i_brand = 'BrandX'
  AND hd.hd_vehicle_count >= 2
  AND ws.ws_net_profit > 0
  AND t.t_second BETWEEN 10 AND 20
  AND i.i_item_sk IN (SELECT i_item_sk FROM common_items)
GROUP BY GROUPING SETS (
    (d.d_year, i.i_brand, w.w_warehouse_name, r.sales_rank),
    (d.d_year, i.i_brand),
    (d.d_year)
  )
ORDER BY d.d_year DESC, total_sales DESC
LIMIT 100
