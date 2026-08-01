WITH store_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_id
)
SELECT s.i_item_id,
       s.total_sales,
       'store' AS channel
FROM store_sales_agg s
UNION ALL
SELECT w.i_item_id,
       w.total_sales,
       'web' AS channel
FROM web_sales_agg w
ORDER BY total_sales DESC
LIMIT 100
