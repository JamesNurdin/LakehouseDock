/* Variant 5: Add a percentile calculation for net profit adjustment */
WITH sales_ship AS (
    SELECT ws_ship_mode_sk AS ship_mode_sk,
           SUM(ws_net_profit) AS total_sales_profit,
           COUNT(*) AS sales_cnt
    FROM web_sales
    GROUP BY ws_ship_mode_sk
),
return_ship AS (
    SELECT cr_ship_mode_sk AS ship_mode_sk,
           SUM(cr_net_loss) AS total_return_loss,
           COUNT(*) AS return_cnt
    FROM catalog_returns
    GROUP BY cr_ship_mode_sk
),
joined AS (
    SELECT COALESCE(s.ship_mode_sk, r.ship_mode_sk) AS ship_mode_sk,
           COALESCE(s.sales_cnt, 0) AS sales_cnt,
           COALESCE(r.return_cnt, 0) AS return_cnt,
           (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_adj
    FROM sales_ship s
    FULL OUTER JOIN return_ship r ON s.ship_mode_sk = r.ship_mode_sk
)
SELECT ship_mode_sk,
       sales_cnt,
       return_cnt,
       net_profit_adj,
       PERCENT_RANK() OVER (ORDER BY net_profit_adj DESC) AS profit_percentile,
       NTILE(4) OVER (ORDER BY net_profit_adj DESC) AS profit_quartile
FROM joined
ORDER BY profit_percentile
LIMIT 20
