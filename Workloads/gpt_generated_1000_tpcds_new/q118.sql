WITH agg_sales AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity
    FROM tpcds.web_sales ws
    WHERE ws.ws_coupon_amt > 100
      AND ws.ws_ship_mode_sk IS NOT NULL
      AND ws.ws_web_page_sk IS NOT NULL
    GROUP BY ws.ws_ship_mode_sk, ws.ws_web_page_sk
)
SELECT
    sm.sm_carrier,
    sm.sm_code,
    wp.wp_type,
    agg.total_net_paid,
    agg.total_quantity
FROM agg_sales agg
JOIN tpcds.ship_mode sm
    ON agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp
    ON agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE sm.sm_carrier IN ('USPS', 'DIAMOND')
  AND sm.sm_code = 'AIR'
  AND wp.wp_char_count > 2000
  AND wp.wp_max_ad_count BETWEEN 1 AND 3
  AND agg.total_net_paid > (
        SELECT MAX(ws.ws_net_paid)
        FROM tpcds.web_sales ws
    )
ORDER BY agg.total_net_paid DESC
LIMIT 100
