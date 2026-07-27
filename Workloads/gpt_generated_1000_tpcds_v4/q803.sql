/*
Goal: Calculate per‑warehouse profit performance for high‑priced items sold to households with multiple dependents and vehicles, categorising profit levels and filtering to only warehouses in California that have high‑potential buyers.
*/
WITH sales_agg AS (
    SELECT
        w.w_warehouse_id AS warehouse_id,
        w.w_city AS city,
        i.i_brand AS brand,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 5000 THEN 'Very High'
            WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High'
            ELSE 'Normal'
        END AS profit_level
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_current_price > 100
      AND i.i_brand_id IN (1001001, 2004002)
      AND hd.hd_dep_count >= 3
      AND hd.hd_vehicle_count >= 2
      AND w.w_state = 'CA'
      AND ws.ws_quantity > 1
      AND ws.ws_ext_discount_amt > 0
      AND EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_demo_sk = ws.ws_bill_hdemo_sk
              AND hd2.hd_buy_potential = '>10000'
      )
    GROUP BY w.w_warehouse_id, w.w_city, i.i_brand
)
SELECT
    warehouse_id,
    city,
    profit_level,
    total_net_profit,
    total_quantity,
    avg_net_profit,
    CASE
        WHEN avg_net_profit > 200 THEN 'Excellent'
        WHEN avg_net_profit > 100 THEN 'Good'
        ELSE 'Average'
    END AS avg_profit_category
FROM sales_agg
WHERE total_net_profit > 1000
  AND total_quantity >= 10
ORDER BY total_net_profit DESC
LIMIT 100
