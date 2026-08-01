/* goal: Identify the top‑ranking warehouses per city by net profit, classify their profit level relative to the overall average, and exclude any warehouse that has at least one loss‑making sale. */
WITH ws_raw AS (
    SELECT
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE td.t_minute IN (5, 10, 15)
      AND td.t_time BETWEEN 6 AND 12
      AND cd.cd_dep_count >= 2
      AND cd.cd_gender = 'M'
      AND w.w_suite_number NOT LIKE 'Suite P%'
      AND ws.ws_quantity > 1
    GROUP BY ws.ws_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state
),
ws_ranked AS (
    SELECT
        ws_raw.*, 
        ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_net_profit DESC) AS profit_rank
    FROM ws_raw
)
SELECT DISTINCT
    r.w_warehouse_name,
    r.w_city,
    r.w_state,
    r.total_net_profit,
    r.total_sales,
    r.order_cnt,
    CASE
        WHEN r.total_net_profit > (SELECT AVG(total_net_profit) FROM ws_ranked) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_category,
    r.profit_rank
FROM ws_ranked r
WHERE r.profit_rank = 1
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = r.ws_warehouse_sk
          AND ws2.ws_net_profit < 0
    )
UNION ALL
SELECT DISTINCT
    r2.w_warehouse_name,
    r2.w_city,
    r2.w_state,
    r2.total_net_profit,
    r2.total_sales,
    r2.order_cnt,
    CASE
        WHEN r2.total_net_profit > (SELECT AVG(total_net_profit) FROM ws_ranked) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_category,
    r2.profit_rank
FROM ws_ranked r2
WHERE r2.profit_rank > 1
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_warehouse_sk = r2.ws_warehouse_sk
          AND ws3.ws_net_profit < 0
    )
ORDER BY total_net_profit DESC
LIMIT 100
