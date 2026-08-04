WITH sampled_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
full_joined AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        sm.sm_carrier,
        wp.wp_type
    FROM sampled_sales ws
    FULL OUTER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT *
FROM (
    SELECT DISTINCT
        fj.ws_order_number,
        fj.ws_net_paid_inc_ship_tax,
        fj.sm_carrier,
        fj.wp_type
    FROM full_joined fj
    WHERE fj.ws_order_number NOT IN (
        SELECT ws2.ws_order_number
        FROM web_sales ws2
        WHERE ws2.ws_net_paid_inc_ship_tax > 5000
    )

    UNION ALL

    SELECT
        CAST(NULL AS INTEGER) AS ws_order_number,
        SUM(ws.ws_net_paid_inc_ship_tax) AS ws_net_paid_inc_ship_tax,
        sm.sm_carrier,
        CAST('TOTAL' AS VARCHAR) AS wp_type
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ship_mode_sk IS NOT NULL
    GROUP BY sm.sm_carrier
) combined
ORDER BY combined.sm_carrier, combined.ws_net_paid_inc_ship_tax DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
