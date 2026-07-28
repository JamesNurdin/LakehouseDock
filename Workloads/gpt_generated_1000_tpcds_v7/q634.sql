WITH sales_by_mode_site AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_code,
        ws_site.web_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM
        web_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE
        sm.sm_type = 'OVERNIGHT'                 -- predicate 1
        AND sm.sm_code = 'AIR'                    -- predicate 2
        AND ws_site.web_state = 'CA'              -- predicate 3
        AND ws.ws_ext_sales_price > 1000          -- predicate 4
        AND ws.ws_quantity >= 2                   -- predicate 5
    GROUP BY
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_code,
        ws_site.web_state
)
SELECT
    sm_type,
    sm_code,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_profit) AS sum_total_profit,
    COUNT(*) AS num_sites
FROM sales_by_mode_site
GROUP BY
    sm_type,
    sm_code
HAVING AVG(total_sales) > 5000
ORDER BY avg_total_sales DESC
LIMIT 10
