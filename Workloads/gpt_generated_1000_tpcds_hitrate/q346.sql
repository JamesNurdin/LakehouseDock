WITH base_sales AS (
    SELECT
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        c.c_customer_id,
        wsit.web_site_id,
        hd.hd_vehicle_count
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990                                 -- predicate 1
      AND ws.ws_ext_wholesale_cost > 1000.00                                   -- predicate 2
      AND wsit.web_state = 'CA'                                                -- predicate 3
      AND hd.hd_vehicle_count > 1                                             -- predicate 4
      AND NOT EXISTS (                                                          -- anti‑join condition
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_order_number = ws.ws_order_number
              AND ws2.ws_ship_mode_sk = ws.ws_ship_mode_sk
              AND ws2.ws_item_sk <> ws.ws_item_sk
        )
),
agg_sales AS (
    SELECT
        web_site_id,
        c_customer_id,
        SUM(ws_net_profit) AS total_profit
    FROM base_sales
    GROUP BY web_site_id, c_customer_id
)
SELECT
    web_site_id,
    c_customer_id,
    total_profit,
    RANK() OVER (PARTITION BY web_site_id ORDER BY total_profit DESC) AS profit_rank,
    CASE WHEN total_profit >= 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM agg_sales
WHERE total_profit > 0                                                      -- additional filter on the aggregated result
ORDER BY profit_rank ASC, total_profit DESC
LIMIT 100
