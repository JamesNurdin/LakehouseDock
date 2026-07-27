/*
  Goal: Compare profitability across warehouses for high‑risk billing customers versus low‑risk shipping customers, counting distinct orders and summing net profit per city.
*/
WITH billed AS (
    SELECT
        w.w_city AS warehouse_city,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_warehouse_sk
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_credit_rating = 'High Risk'
      AND cd.cd_purchase_estimate > 6000
      AND ws.ws_net_profit > (
          SELECT avg(ws2.ws_net_profit)
          FROM web_sales ws2
          WHERE ws2.ws_warehouse_sk = ws.ws_warehouse_sk
      )
),
shipped AS (
    SELECT
        w.w_city AS warehouse_city,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_warehouse_sk
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cd.cd_purchase_estimate < 3000
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd2
          WHERE cd2.cd_demo_sk = ws.ws_ship_cdemo_sk
            AND cd2.cd_dep_college_count >= 2
      )
)
SELECT
    warehouse_city,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_net_profit) AS total_profit
FROM (
    SELECT warehouse_city, ws_order_number, ws_net_profit, ws_warehouse_sk FROM billed
    UNION ALL
    SELECT warehouse_city, ws_order_number, ws_net_profit, ws_warehouse_sk FROM shipped
) u
GROUP BY warehouse_city
ORDER BY total_profit DESC
LIMIT 100
