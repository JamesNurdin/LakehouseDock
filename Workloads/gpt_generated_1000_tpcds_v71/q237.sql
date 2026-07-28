WITH avg_price AS (
    SELECT i_category, AVG(i_current_price) AS avg_price_cat
    FROM item
    GROUP BY i_category
)
SELECT
    i.i_item_id,
    i.i_category,
    w.w_state,
    SUM(ss.ss_net_paid)            AS store_sales_net,
    SUM(ws.ws_net_paid)            AS web_sales_net,
    SUM(sr.sr_return_amt)          AS total_returns,
    AVG(ap.avg_price_cat)          AS avg_category_price,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM store_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_current
    ON c.c_current_addr_sk = ca_current.ca_address_sk
JOIN customer_demographics cd_current
    ON c.c_current_cdemo_sk = cd_current.cd_demo_sk
JOIN avg_price ap
    ON i.i_category = ap.i_category
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws_check
    WHERE ws_check.ws_item_sk = i.i_item_sk
      AND ws_check.ws_net_paid > 1000
)
GROUP BY ROLLUP (i.i_category, w.w_state, i.i_item_id)
HAVING SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 10000
ORDER BY SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) DESC
LIMIT 100
