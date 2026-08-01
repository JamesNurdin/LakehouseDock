SELECT
    i_s.i_item_id,
    sm.sm_type,
    ca_sales.ca_state AS sales_state,
    ca_web_bill.ca_state AS web_state,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
    AVG(ws.ws_ext_sales_price) AS avg_web_sales_per_item,
    (SELECT AVG(ss_ext_sales_price) FROM store_sales) AS overall_avg_store_sales,
    (SELECT AVG(ws_ext_sales_price) FROM web_sales) AS overall_avg_web_sales
FROM store_sales ss
JOIN item i_s
    ON ss.ss_item_sk = i_s.i_item_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN item i_sr
    ON sr.sr_item_sk = i_sr.i_item_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i_s.i_item_sk
JOIN item i_w
    ON ws.ws_item_sk = i_w.i_item_sk
JOIN customer_demographics cd_ws_bill
    ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN customer_address ca_web_bill
    ON ws.ws_bill_addr_sk = ca_web_bill.ca_address_sk
JOIN customer_demographics cd_ws_ship
    ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN customer_address ca_web_ship
    ON ws.ws_ship_addr_sk = ca_web_ship.ca_address_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE r.r_reason_desc LIKE '%warranty%'
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = ss.ss_item_sk
          AND ws2.ws_quantity > 10
    )
GROUP BY
    GROUPING SETS (
        (i_s.i_item_id, sm.sm_type, ca_sales.ca_state, ca_web_bill.ca_state),
        (i_s.i_item_id, sm.sm_type),
        (i_s.i_item_id),
        (sm.sm_type),
        ()
    )
ORDER BY total_store_sales DESC
LIMIT 100
