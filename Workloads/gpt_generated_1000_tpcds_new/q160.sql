WITH recent_promos AS (
        SELECT p_promo_sk, p_promo_name
        FROM promotion
        WHERE p_discount_active = 'Y'
        LIMIT 10
    ),
    num_buckets AS (
        SELECT v AS bucket
        FROM (VALUES 1, 2, 3) AS t(v)
    )
SELECT
    ws1.ws_order_number AS order_number,
    ca1.ca_state AS state,
    p1.p_promo_name AS promo_name,
    ws1.ws_net_paid_inc_tax AS net_paid_inc_tax,
    wp1.wp_url AS page_url
FROM web_sales ws1
JOIN customer_address ca1 ON ws1.ws_bill_addr_sk = ca1.ca_address_sk
JOIN promotion p1 ON ws1.ws_promo_sk = p1.p_promo_sk
JOIN web_page wp1 ON ws1.ws_web_page_sk = wp1.wp_web_page_sk
WHERE ws1.ws_net_paid_inc_tax > (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = 122480
    )
  AND p1.p_channel_email = 'N'
  AND wp1.wp_image_count > 2
UNION ALL
SELECT
    ws2.ws_order_number AS order_number,
    ca2.ca_state AS state,
    rp.p_promo_name AS promo_name,
    ws2.ws_net_paid_inc_tax * nb.bucket AS net_paid_inc_tax,
    wp2.wp_url AS page_url
FROM web_sales ws2
JOIN customer_address ca2 ON ws2.ws_ship_addr_sk = ca2.ca_address_sk
JOIN recent_promos rp ON ws2.ws_promo_sk = rp.p_promo_sk
JOIN web_page wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
CROSS JOIN num_buckets nb
WHERE ws2.ws_net_paid_inc_tax < (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = 60304
    )
  AND rp.p_promo_name IS NOT NULL
  AND wp2.wp_autogen_flag = 'Y'
ORDER BY net_paid_inc_tax DESC, order_number
LIMIT 100
