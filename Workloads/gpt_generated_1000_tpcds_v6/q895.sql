WITH sales_union AS (
        SELECT DISTINCT ss_customer_sk AS cust_sk,
               ss_net_profit AS profit,
               ss_item_sk AS item_sk,
               'store' AS channel
        FROM store_sales
        WHERE ss_net_profit > 0
        UNION ALL
        SELECT DISTINCT ws_bill_customer_sk AS cust_sk,
               ws_net_profit AS profit,
               ws_item_sk AS item_sk,
               'web' AS channel
        FROM web_sales
        WHERE ws_net_profit > 0
    ),
    high_value_customers AS (
        SELECT cust_sk
        FROM sales_union
        GROUP BY cust_sk
        HAVING SUM(profit) > 5000
    )
SELECT
    s.s_store_name,
    sm.sm_carrier,
    ib.ib_income_band_sk,
    cd.cd_gender,
    COUNT(DISTINCT su.item_sk) AS distinct_items_sold,
    SUM(su.profit) AS total_profit,
    COALESCE(s.s_floor_space, 0) AS store_floor_space,
    COALESCE(sm.sm_type, 'UNKNOWN') AS ship_mode_type
FROM sales_union su
JOIN customer c
    ON su.cust_sk = c.c_customer_sk
LEFT JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN "store" s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
WHERE c.c_customer_sk IN (SELECT cust_sk FROM high_value_customers)
GROUP BY s.s_store_name,
         sm.sm_carrier,
         ib.ib_income_band_sk,
         cd.cd_gender,
         s.s_floor_space,
         sm.sm_type
ORDER BY total_profit DESC
LIMIT 100
