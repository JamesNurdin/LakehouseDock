/* Variant 4: Use a HAVING clause to keep only ship modes with profit rank > 5 and add ORDER BY total counts */
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
),
joined AS (
    SELECT COALESCE(s.ship_mode_sk, r.ship_mode_sk) AS ship_mode_sk,
           COALESCE(s.sales_cnt, 0) AS sales_cnt,
           COALESCE(r.return_cnt, 0) AS return_cnt,
           COALESCE(s.avg_ship_cost_sales, 0) AS avg_ship_cost_sales,
           COALESCE(r.avg_ship_cost_returns, 0) AS avg_ship_cost_returns,
           (COALESCE(s.avg_ship_cost_sales, 0) - COALESCE(r.avg_ship_cost_returns, 0)) AS ship_cost_diff,
           (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_adj,
           DENSE_RANK() OVER (ORDER BY (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
    FROM sales_ship s
    FULL OUTER JOIN return_ship r ON s.ship_mode_sk = r.ship_mode_sk
)
SELECT *
FROM joined
WHERE profit_rank > 5
ORDER BY (sales_cnt + return_cnt) DESC
LIMIT 10
