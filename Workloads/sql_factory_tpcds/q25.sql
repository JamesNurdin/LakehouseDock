/* Variant 6: Pivot ship mode profits into columns using conditional aggregation */
WITH sales_ship AS (
    SELECT ws_ship_mode_sk,
           SUM(ws_net_profit) AS total_sales_profit
    FROM web_sales
    GROUP BY ws_ship_mode_sk
),
return_ship AS (
    SELECT cr_ship_mode_sk,
           SUM(cr_net_loss) AS total_return_loss
    FROM catalog_returns
    GROUP BY cr_ship_mode_sk
),
joined AS (
    SELECT COALESCE(s.ws_ship_mode_sk, r.cr_ship_mode_sk) AS ship_mode_sk,
           COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
           COALESCE(r.total_return_loss, 0) AS total_return_loss
    FROM sales_ship s
    FULL OUTER JOIN return_ship r ON s.ws_ship_mode_sk = r.cr_ship_mode_sk
)
SELECT
    MAX(CASE WHEN ship_mode_sk = 1 THEN total_sales_profit - total_return_loss END) AS mode_1_profit_adj,
    MAX(CASE WHEN ship_mode_sk = 2 THEN total_sales_profit - total_return_loss END) AS mode_2_profit_adj,
    MAX(CASE WHEN ship_mode_sk = 3 THEN total_sales_profit - total_return_loss END) AS mode_3_profit_adj,
    MAX(CASE WHEN ship_mode_sk = 4 THEN total_sales_profit - total_return_loss END) AS mode_4_profit_adj
FROM joined
