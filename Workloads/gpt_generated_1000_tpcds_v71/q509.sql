/*
Goal: Analyze web sales performance by website, time of day, and shipping mode, showing total and average sales, profit flag, and key dimensions while applying realistic filters.
*/
WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt,
        MIN(ws.ws_ext_sales_price) AS min_sale,
        MAX(ws.ws_ext_sales_price) AS max_sale,
        CASE
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Positive'
            ELSE 'NonPositive'
        END AS profit_flag
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 1000            -- filter on sizable sales amount
      AND ws.ws_quantity >= 2                     -- filter on multi‑item orders
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_time_sk, ws.ws_ship_mode_sk
)
SELECT
    sa.ws_web_site_sk,
    sa.ws_sold_time_sk,
    sa.ws_ship_mode_sk,
    sa.total_sales,
    sa.avg_profit,
    sa.order_cnt,
    sa.min_sale,
    sa.max_sale,
    sa.profit_flag,
    td.t_sub_shift,
    sm.sm_type,
    sm.sm_carrier,
    ws.web_company_name
FROM sales_agg sa
JOIN time_dim td
    ON sa.ws_sold_time_sk = td.t_time_sk
JOIN web_site ws
    ON sa.ws_web_site_sk = ws.web_site_sk
JOIN ship_mode sm
    ON sa.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE td.t_sub_shift IN ('morning', 'afternoon')                -- filter on desired shifts
  AND td.t_time BETWEEN 10 AND 12                              -- filter on early day hours
  AND ws.web_company_name IN ('anti', 'able')                  -- focus on two sample companies
  AND EXISTS (
        SELECT 1
        FROM ship_mode sm2
        WHERE sm2.sm_ship_mode_sk = sa.ws_ship_mode_sk
          AND sm2.sm_carrier = 'UPS'                           -- only UPS shipments
    )
ORDER BY sa.total_sales DESC
LIMIT 100
