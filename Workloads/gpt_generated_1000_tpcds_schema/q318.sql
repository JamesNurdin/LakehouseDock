WITH filtered_items AS (
  SELECT i_item_sk,
         i_item_desc,
         i_brand,
         substr(i_item_desc, 1, 10) AS item_prefix
  FROM item
  WHERE regexp_like(i_item_desc, '[A-Z]{2}')
    AND i_item_desc LIKE '%BRUSH%'
),
store_sales_agg AS (
  SELECT d.d_year,
         s.s_state,
         i.i_brand,
         SUM(ss.ss_net_paid) AS total_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN filtered_items i ON ss.ss_item_sk = i.i_item_sk
  WHERE ss.ss_store_sk IN (
    SELECT s2.s_store_sk
    FROM store s2
    WHERE s2.s_city LIKE 'Los%'
  )
  GROUP BY CUBE (d.d_year, s.s_state, i.i_brand)
),
web_sales_agg AS (
  SELECT d.d_year,
         w.w_state AS s_state,
         i.i_brand,
         SUM(ws.ws_net_paid) AS total_net_paid
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN filtered_items i ON ws.ws_item_sk = i.i_item_sk
  WHERE ws.ws_ship_mode_sk IN (
    SELECT sm.sm_ship_mode_sk
    FROM ship_mode sm
    WHERE sm.sm_type LIKE 'AIR%'
  )
  GROUP BY CUBE (d.d_year, w.w_state, i.i_brand)
)
SELECT
  d_year,
  s_state,
  i_brand,
  SUM(total_net_paid) AS agg_net_paid
FROM (
  SELECT * FROM store_sales_agg
  UNION DISTINCT
  SELECT * FROM web_sales_agg
) u
GROUP BY CUBE (d_year, s_state, i_brand)
ORDER BY agg_net_paid DESC
LIMIT 100
