WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_wholesale_cost,
        ws.ws_net_profit,
        ws.ws_quantity,
        CASE WHEN ws.ws_net_profit > 200 THEN 1 ELSE 0 END AS high_profit_flag
    FROM tpcds.web_sales ws
    WHERE ws.ws_net_paid_inc_tax > 1000
      AND ws.ws_quantity > 2
      AND ws.ws_wholesale_cost > 50
)
SELECT
    hd.hd_buy_potential,
    CASE WHEN hd.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END AS vehicle_status,
    COUNT(DISTINCT fs.ws_order_number) AS order_cnt,
    SUM(fs.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(fs.ws_wholesale_cost) AS avg_wholesale_cost,
    SUM(CASE WHEN fs.ws_net_profit > 200 THEN fs.ws_net_profit ELSE 0 END) AS high_profit_sum,
    MAX(fs.ws_net_profit) AS max_net_profit,
    MIN(fs.ws_wholesale_cost) AS min_wholesale_cost,
    (
        SELECT AVG(inner_ws.ws_net_profit)
        FROM tpcds.web_sales inner_ws
    ) AS overall_avg_net_profit
FROM filtered_sales fs
JOIN tpcds.household_demographics hd
    ON fs.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential IN ('1001-5000', '5001-10000')
  AND hd.hd_vehicle_count >= 1
  AND EXISTS (
        SELECT 1
        FROM tpcds.household_demographics hd_ship
        WHERE hd_ship.hd_demo_sk = fs.ws_ship_hdemo_sk
          AND hd_ship.hd_dep_count > 5
    )
  AND fs.ws_bill_customer_sk IN (
        SELECT DISTINCT ws_inner.ws_bill_customer_sk
        FROM tpcds.web_sales ws_inner
        WHERE ws_inner.ws_net_profit > 300
    )
GROUP BY
    hd.hd_buy_potential,
    CASE WHEN hd.hd_vehicle_count > 0 THEN 'HasVehicle' ELSE 'NoVehicle' END
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
