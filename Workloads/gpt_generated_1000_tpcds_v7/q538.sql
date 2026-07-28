WITH sales_enriched AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_order_number
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 1
)
SELECT
    i.i_category,
    sm.sm_carrier,
    ws_site.web_state,
    SUM(s.ws_net_paid) AS total_net_paid,
    AVG(s.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT s.ws_order_number) AS distinct_orders,
    MIN(s.ws_net_paid) AS min_net_paid,
    MAX(s.ws_net_paid) AS max_net_paid
FROM sales_enriched s
JOIN tpcds.item i
    ON s.ws_item_sk = i.i_item_sk
JOIN tpcds.ship_mode sm
    ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_site ws_site
    ON s.ws_web_site_sk = ws_site.web_site_sk
WHERE i.i_size = 'medium'
  AND i.i_category_id IN (2, 9)
  AND i.i_manager_id = 63
  AND sm.sm_contract = 'A5BYO1qH8HGTTN'
  AND sm.sm_carrier = 'ORIENTAL'
  AND ws_site.web_city = 'Hill Hill'
  AND ws_site.web_state = 'CA'
GROUP BY
    i.i_category,
    sm.sm_carrier,
    ws_site.web_state
ORDER BY total_net_paid DESC
LIMIT 100
