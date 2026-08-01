WITH sales_data AS (
   SELECT
      ws.ws_order_number,
      ws.ws_item_sk,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      wh.w_warehouse_name AS warehouse_name,
      sm.sm_type AS ship_mode_type,
      hd_bill.hd_income_band_sk AS hd_income_band,
      sr.sr_net_loss AS store_return_loss,
      wr.wr_net_loss AS web_return_loss,
      c_bill.c_customer_id AS bill_customer_id,
      c_ship.c_customer_id AS ship_customer_id,
      inv.inv_quantity_on_hand,
      s.s_store_name,
      wp.wp_url AS sales_page_url,
      wp2.wp_url AS return_page_url
   FROM web_sales ws
   JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
   JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
   JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
   JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
   JOIN inventory inv
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
   LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c_bill.c_customer_sk
   LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = ws.ws_item_sk
   LEFT JOIN web_page wp2
        ON wr.wr_web_page_sk = wp2.wp_web_page_sk
),
aggregated AS (
   SELECT
      warehouse_name,
      ship_mode_type,
      hd_income_band,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_net_profit) AS total_net_profit,
      SUM(COALESCE(store_return_loss, 0) + COALESCE(web_return_loss, 0)) AS total_return_loss,
      CASE
         WHEN SUM(ws_net_profit) > 0 THEN 'Profit'
         WHEN SUM(ws_net_profit) = 0 THEN 'Break-even'
         ELSE 'Loss'
      END AS profit_category
   FROM sales_data
   GROUP BY ROLLUP (warehouse_name, ship_mode_type, hd_income_band)
)
SELECT
   warehouse_name,
   ship_mode_type,
   hd_income_band,
   total_sales,
   total_net_profit,
   total_return_loss,
   profit_category,
   RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 100
