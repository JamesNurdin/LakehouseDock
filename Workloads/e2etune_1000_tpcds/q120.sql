WITH ws_daily AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        SUM(ws_net_paid) AS daily_net_paid,
        SUM(ws_ext_sales_price) AS daily_ext_sales_price,
        COUNT(DISTINCT ws_order_number) AS daily_order_cnt,
        AVG(ws_quantity) AS avg_daily_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ws_warehouse_sk, ws_sold_date_sk
)
SELECT
    cc.cc_state,
    ib.ib_income_band_sk,
    SUM(ws_daily.daily_net_paid) AS total_net_paid,
    SUM(ws_daily.daily_ext_sales_price) AS total_ext_sales_price,
    AVG(ws_daily.avg_daily_quantity) AS overall_avg_quantity,
    COUNT(DISTINCT ws_daily.ws_sold_date_sk) AS selling_days,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY SUM(ws_daily.daily_net_paid) DESC) AS net_paid_rank,
    CASE 
        WHEN SUM(ws_daily.daily_net_paid) > 1000000 THEN 'HIGH'
        WHEN SUM(ws_daily.daily_net_paid) > 500000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_paid_category
FROM ws_daily
JOIN call_center cc
    ON ws_daily.ws_warehouse_sk = cc.cc_call_center_sk
JOIN income_band ib
    ON cc.cc_employees BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE cc.cc_country = 'United States'
  AND cc.cc_employees > 1500000
GROUP BY cc.cc_state, ib.ib_income_band_sk
HAVING SUM(ws_daily.daily_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 50
