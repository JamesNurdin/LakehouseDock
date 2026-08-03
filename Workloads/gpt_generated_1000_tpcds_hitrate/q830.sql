WITH filtered_ship_modes AS (
    SELECT sm_ship_mode_sk,
           sm_carrier,
           sm_contract,
           sm_type
    FROM ship_mode
    WHERE sm_carrier IN ('FEDEX', 'MSC')
),
combined AS (
    SELECT
        sm.sm_carrier,
        sm.sm_contract,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    RIGHT JOIN filtered_ship_modes sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_ship_customer_sk = ws.ws_ship_customer_sk
              AND ws2.ws_ext_tax > 30
        )
      AND ws.ws_ext_tax > 20
    GROUP BY CUBE (sm.sm_carrier, sm.sm_contract)
    HAVING SUM(ws.ws_net_profit) > 0

    UNION ALL

    SELECT
        sm.sm_carrier,
        sm.sm_contract,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    RIGHT JOIN filtered_ship_modes sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_ship_customer_sk = ws.ws_ship_customer_sk
              AND ws2.ws_ext_tax > 50
        )
      AND ws.ws_ext_tax BETWEEN 10 AND 200
    GROUP BY CUBE (sm.sm_carrier, sm.sm_contract)
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    rd.report_date,
    c.sm_carrier,
    c.sm_contract,
    c.total_sales,
    c.total_profit
FROM combined c
CROSS JOIN (VALUES DATE '2023-01-01', DATE '2023-01-02') AS rd(report_date)
ORDER BY c.total_sales DESC, rd.report_date
LIMIT 100
