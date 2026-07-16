WITH filtered_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_wholesale_cost,
        ws_net_paid,
        ws_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451383 AND 2451945
      AND ws_quantity > 0
),
banded_sales AS (
    SELECT 
        fs.ws_sold_date_sk,
        fs.ws_item_sk,
        fs.ws_quantity,
        fs.ws_wholesale_cost,
        fs.ws_net_paid,
        fs.ws_net_profit,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM filtered_sales fs
    JOIN income_band ib
      ON fs.ws_wholesale_cost >= ib.ib_lower_bound
     AND fs.ws_wholesale_cost < ib.ib_upper_bound
),
agg_sales AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_wholesale_cost) AS avg_wholesale_cost,
        SUM(ws_net_profit) AS total_net_profit
    FROM banded_sales
    GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound, ws_sold_date_sk
    HAVING SUM(ws_quantity) > 100
)
SELECT 
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    ws_sold_date_sk,
    total_quantity,
    total_net_paid,
    avg_wholesale_cost,
    total_net_profit,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_profit DESC) AS profit_rank,
    SUM(total_net_profit) OVER (PARTITION BY ib_income_band_sk ORDER BY ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_to_date,
    CASE 
        WHEN total_net_profit > 100000 THEN 'HIGH'
        WHEN total_net_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM agg_sales
ORDER BY ib_income_band_sk, total_net_profit DESC
LIMIT 100
