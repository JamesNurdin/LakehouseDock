WITH ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        ws_web_page_sk,
        SUM(ws_ext_sales_price)   AS total_sales,
        SUM(ws_net_profit)        AS total_profit,
        COUNT(*)                  AS order_cnt
    FROM
        web_sales
    WHERE
        ws_ship_hdemo_sk IN (4554, 782, 3114)               -- filter 1
        AND ws_bill_hdemo_sk = 5825                        -- filter 2
        AND ws_ext_wholesale_cost > 500                    -- filter 3
        AND ws_ext_wholesale_cost < 3000                   -- filter 4
        AND ws_sold_date_sk BETWEEN 2450000 AND 2455000   -- filter 5
    GROUP BY
        ws_ship_mode_sk,
        ws_web_page_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    wp.wp_web_page_id,
    wp.wp_type,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt
FROM
    ws_agg
    JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp   ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    wp.wp_rec_end_date >= DATE '2000-01-01'               -- filter 6
    AND wp.wp_rec_end_date <= DATE '2001-12-31'            -- filter 7
    AND wp.wp_access_date_sk = 2452623                    -- filter 8
    AND sm.sm_carrier = 'UPS'                              -- filter 9
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    wp.wp_web_page_id,
    wp.wp_type,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt
ORDER BY
    ws_agg.total_sales DESC
LIMIT 100
