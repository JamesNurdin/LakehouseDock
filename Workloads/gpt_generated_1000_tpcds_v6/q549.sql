WITH cs_agg AS (
        SELECT
            cs_promo_sk,
            cs_ship_mode_sk,
            SUM(cs_net_paid) AS sum_cs_net_paid,
            COUNT(*) AS cnt_cs
        FROM catalog_sales
        WHERE cs_coupon_amt > 100
          AND cs_ext_list_price < 5000
        GROUP BY cs_promo_sk, cs_ship_mode_sk
    ),
    ws_agg AS (
        SELECT
            ws_promo_sk,
            ws_ship_mode_sk,
            ws_web_site_sk,
            ws_web_page_sk,
            SUM(ws_net_paid) AS sum_ws_net_paid,
            COUNT(*) AS cnt_ws
        FROM web_sales
        WHERE ws_coupon_amt > 50
          AND ws_ext_list_price < 4000
        GROUP BY ws_promo_sk, ws_ship_mode_sk, ws_web_site_sk, ws_web_page_sk
    )
SELECT
    p.p_promo_name,
    sm.sm_type,
    wp.wp_type,
    ws_agg.sum_ws_net_paid,
    cs_agg.sum_cs_net_paid,
    (cs_agg.sum_cs_net_paid + ws_agg.sum_ws_net_paid) AS total_net_paid,
    ws_agg.cnt_ws,
    cs_agg.cnt_cs,
    ws_agg.sum_ws_net_paid / NULLIF(ws_agg.cnt_ws, 0) AS avg_ws_net_paid,
    (
        SELECT AVG(cs2.cs_ext_discount_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_promo_sk = p.p_promo_sk
    ) AS avg_cs_discount
FROM cs_agg
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN ws_agg
    ON ws_agg.ws_promo_sk = p.p_promo_sk
   AND ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws
    ON ws_agg.ws_web_site_sk = ws.web_site_sk
JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE p.p_channel_event = 'N'
  AND sm.sm_type = 'EXPRESS'
  AND ws.web_state = 'TX'
  AND wp.wp_char_count > 500
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        JOIN customer_address ca
            ON ws2.ws_ship_addr_sk = ca.ca_address_sk
        WHERE ws2.ws_web_site_sk = ws.web_site_sk
          AND ca.ca_state = 'CA'
    )
ORDER BY total_net_paid DESC
LIMIT 100
