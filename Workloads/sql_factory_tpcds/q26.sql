/* Variant 2: Add a windowed running total of profit and order by ship mode */
WITH sales_ship AS (
    SELECT ws_ship_mode_sk AS ship_mode_sk,
           AVG(ws_ext_ship_cost) AS avg_ship_cost_sales,
           SUM(ws_net_profit) AS total_sales_profit,
           COUNT(*) AS sales_cnt
    FROM web_sales
    GROUP BY ws_ship_mode_sk
),
return_ship AS (
    SELECT cr_ship_mode_sk AS ship_mode_sk,
           AVG(cr_return_ship_cost) AS avg_ship_cost_returns,
           SUM(cr_net_loss) AS total_return_loss,
           COUNT(*) AS return_cnt
    FROM catalog_returns
    GROUP BY cr_ship_mode_sk
)
SELECT COALESCE(s.ship_mode_sk, r.ship_mode_sk) AS ship_mode_sk,
       COALESCE(s.sales_cnt, 0) AS sales_cnt,
       COALESCE(r.return_cnt, 0) AS return_cnt,
       COALESCE(s.avg_ship_cost_sales, 0) AS avg_ship_cost_sales,
       COALESCE(r.avg_ship_cost_returns, 0) AS avg_ship_cost_returns,
       (COALESCE(s.avg_ship_cost_sales, 0) - COALESCE(r.avg_ship_cost_returns, 0)) AS ship_cost_diff,
       (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_adj,
       SUM(COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) OVER (ORDER BY COALESCE(s.ship_mode_sk, r.ship_mode_sk) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit_adj
FROM sales_ship s
FULL OUTER JOIN return_ship r ON s.ship_mode_sk = r.ship_mode_sk
ORDER BY ship_mode_sk
