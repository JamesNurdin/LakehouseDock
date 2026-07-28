WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_item_sk,
       i.i_item_id,
       i.i_current_price,
       ss.ss_quantity,
       ss.ss_net_paid,
       ss.ss_net_profit,
       hd.hd_demo_sk,
       hd.hd_income_band_sk,
       hd.hd_vehicle_count,
       ws.ws_order_number,
       ws.ws_net_paid_inc_ship_tax,
       ws.ws_net_profit AS ws_net_profit,
       wp.wp_web_page_id,
       wp.wp_type,
       r.r_reason_desc,
       wsite.web_site_id,
       wsite.web_state,
       (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2 WHERE ss2.ss_item_sk = ss.ss_item_sk) AS avg_store_discount,
       (SELECT AVG(ws2.ws_ext_discount_amt) FROM web_sales ws2 WHERE ws2.ws_item_sk = i.i_item_sk) AS avg_web_discount
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   WHERE ss.ss_list_price > 30
     AND ss.ss_ext_tax < 100
     AND i.i_current_price BETWEEN 10 AND 200
     AND hd.hd_vehicle_count >= 2
     AND ws.ws_net_paid_inc_ship_tax > 1000
     AND i.i_rec_start_date >= DATE '2001-01-01'
     AND wsite.web_state = 'CA'
),
high_store AS (
   SELECT
       ss_sold_date_sk,
       ss_item_sk,
       i_item_id,
       i_current_price,
       ss_quantity,
       ss_net_paid,
       ss_net_profit,
       hd_demo_sk,
       hd_income_band_sk,
       hd_vehicle_count,
       ws_order_number,
       ws_net_paid_inc_ship_tax,
       ws_net_profit,
       wp_web_page_id,
       wp_type,
       r_reason_desc,
       web_site_id,
       web_state,
       avg_store_discount,
       avg_web_discount
   FROM base
   WHERE ss_net_profit > 500
),
high_web AS (
   SELECT
       ss_sold_date_sk,
       ss_item_sk,
       i_item_id,
       i_current_price,
       ss_quantity,
       ss_net_paid,
       ss_net_profit,
       hd_demo_sk,
       hd_income_band_sk,
       hd_vehicle_count,
       ws_order_number,
       ws_net_paid_inc_ship_tax,
       ws_net_profit,
       wp_web_page_id,
       wp_type,
       r_reason_desc,
       web_site_id,
       web_state,
       avg_store_discount,
       avg_web_discount
   FROM base
   WHERE ws_net_profit > 800
),
combined AS (
   SELECT * FROM high_store
   UNION ALL
   SELECT * FROM high_web
)
SELECT
   combined.hd_demo_sk,
   combined.hd_income_band_sk,
   combined.i_item_id,
   combined.i_current_price,
   combined.ss_quantity,
   combined.ss_net_profit,
   combined.ws_net_profit,
   combined.wp_web_page_id,
   combined.r_reason_desc,
   combined.web_site_id,
   combined.web_state,
   combined.avg_store_discount,
   combined.avg_web_discount,
   ROW_NUMBER() OVER (PARTITION BY combined.hd_demo_sk ORDER BY (combined.ss_net_profit + combined.ws_net_profit) DESC) AS rank_within_demo
FROM combined
WHERE combined.avg_store_discount IS NOT NULL
ORDER BY rank_within_demo
LIMIT 100
