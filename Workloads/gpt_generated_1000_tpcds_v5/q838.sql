WITH ss_agg AS (
    SELECT ss_item_sk,
           SUM(ss_net_paid) AS ss_total_net_paid,
           COUNT(*) AS ss_txn_cnt
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_item_sk
)
SELECT
    ws.ws_order_number,
    i.i_item_id,
    i.i_product_name,
    ws.ws_net_paid,
    ss_agg.ss_total_net_paid,
    CASE WHEN ws.ws_net_paid > ss_agg.ss_total_net_paid THEN 'WEB_HIGH' ELSE 'WEB_LOW' END AS sales_comparison,
    p.p_promo_name,
    sm.sm_type,
    ws.ws_ship_mode_sk,
    ws.ws_quantity,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY ws.ws_net_paid DESC) AS rn_item_web,
    DENSE_RANK() OVER (ORDER BY ws.ws_net_paid DESC) AS dr_global
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN ss_agg ON ss_agg.ss_item_sk = i.i_item_sk
WHERE
    ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    AND ws.ws_quantity >= 1
    AND p.p_purpose = 'Unknown'
    AND sm.sm_code IN ('AIR', 'SEA')
ORDER BY ws.ws_net_paid DESC
LIMIT 100
