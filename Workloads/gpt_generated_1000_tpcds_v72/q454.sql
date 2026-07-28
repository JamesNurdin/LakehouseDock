WITH ws_avg_profit AS (
        SELECT ss_item_sk,
               AVG(ss_net_profit) AS avg_profit
        FROM store_sales
        GROUP BY ss_item_sk
    )
SELECT
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        sm.sm_type,
        r.r_reason_desc,
        SUM(ws.ws_net_paid)                AS total_net_paid,
        AVG(ws.ws_sales_price)             AS avg_sales_price,
        COUNT(*)                           AS transaction_cnt,
        MIN(ws.ws_sold_date_sk)            AS first_sold_date_sk,
        MAX(ws.ws_sold_date_sk)            AS last_sold_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
     ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN catalog_returns cr
     ON cr.cr_item_sk = i.i_item_sk
JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss
     ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN ws_avg_profit ap
       ON ap.ss_item_sk = i.i_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 2452000 AND 2452100
  AND i.i_category = 'Electronics'
  AND c.c_last_name = 'Hamilton'
  AND w.w_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc LIKE '%model%'
  AND ws.ws_net_paid > COALESCE(ap.avg_profit, 0)
GROUP BY i.i_item_id,
         i.i_product_name,
         w.w_warehouse_name,
         sm.sm_type,
         r.r_reason_desc
HAVING SUM(ws.ws_net_paid) > 5000
   AND COUNT(DISTINCT ws.ws_order_number) >= 3
ORDER BY total_net_paid DESC
LIMIT 100
