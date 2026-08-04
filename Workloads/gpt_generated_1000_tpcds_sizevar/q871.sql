WITH base_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_ship_mode_sk IN (
        SELECT sm_ship_mode_sk
        FROM ship_mode
        WHERE sm_contract = 'P7FBIt8yd'
    )
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    p1.p_promo_name,
    p2.p_channel_email,
    sm1.sm_type AS ship_type_1,
    sm2.sm_type AS ship_type_2,
    w1.w_city AS warehouse_city_1,
    w2.w_city AS warehouse_city_2,
    wp1.wp_url AS page_url_1,
    wp2.wp_url AS page_url_2,
    lat.qty_sum,
    promo_counts.promo_cnt
FROM base_ws ws
JOIN promotion p1 ON ws.ws_promo_sk = p1.p_promo_sk
JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
JOIN ship_mode sm1 ON ws.ws_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN warehouse w1 ON ws.ws_warehouse_sk = w1.w_warehouse_sk
JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
JOIN web_page wp1 ON ws.ws_web_page_sk = wp1.wp_web_page_sk
JOIN web_page wp2 ON ws.ws_web_page_sk = wp2.wp_web_page_sk
FULL OUTER JOIN (
    SELECT p.p_promo_sk, p.p_promo_name, COUNT(*) AS promo_cnt
    FROM promotion p
    GROUP BY p.p_promo_sk, p.p_promo_name
) promo_counts ON ws.ws_promo_sk = promo_counts.p_promo_sk
CROSS JOIN UNNEST(ARRAY[1, 2, 3]) AS t(day_of_week)
LEFT JOIN LATERAL (
    SELECT SUM(ws_quantity) AS qty_sum
    FROM web_sales ws2
    WHERE ws2.ws_warehouse_sk = w1.w_warehouse_sk
) lat ON TRUE
ORDER BY ws.ws_order_number
OFFSET 0 LIMIT 100
