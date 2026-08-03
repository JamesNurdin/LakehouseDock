WITH ws_summary AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
intersect_orders AS (
    SELECT ws_order_number FROM web_sales WHERE ws_net_profit > 0
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 5
)
SELECT
    d_sold.d_year,
    ca_bill.ca_state,
    CASE
        WHEN SUM(ws_summary.ws_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(ws_summary.ws_net_profit) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_bucket,
    SUM(ws_summary.ws_ext_sales_price) AS total_sales,
    SUM(ws_summary.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_summary.ws_order_number) AS order_cnt,
    (SELECT AVG(ws_net_profit) FROM web_sales) AS avg_profit
FROM ws_summary
JOIN date_dim d_sold ON ws_summary.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws_summary.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON ws_summary.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws_summary.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm ON ws_summary.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON ws_summary.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws_summary.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site ON ws_summary.ws_web_site_sk = ws_site.web_site_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
FULL OUTER JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN call_center cc2 ON cc2.cc_closed_date_sk = d_cc_open.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
WHERE ws_summary.ws_order_number NOT IN (
        SELECT ws_order_number FROM web_sales WHERE ws_quantity = 0
    )
  AND ws_summary.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
GROUP BY d_sold.d_year, ca_bill.ca_state
ORDER BY total_profit DESC
LIMIT 100
