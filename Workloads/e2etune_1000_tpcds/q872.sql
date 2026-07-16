WITH daily_item AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           SUM(ws_net_profit) AS total_profit,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450800 AND 2450850
      AND ws_net_profit > 0
    GROUP BY ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_quantity) > 5
),

daily_avg AS (
    SELECT ws_sold_date_sk,
           AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450800 AND 2450850
      AND ws_net_profit > 0
    GROUP BY ws_sold_date_sk
)
SELECT di.ws_sold_date_sk,
       di.ws_item_sk,
       di.total_profit,
       da.avg_profit,
       di.total_profit / da.avg_profit AS profit_to_avg_ratio,
       RANK() OVER (PARTITION BY di.ws_sold_date_sk ORDER BY di.total_profit / da.avg_profit DESC) AS profit_rank
FROM daily_item di
JOIN daily_avg da ON di.ws_sold_date_sk = da.ws_sold_date_sk
ORDER BY di.ws_sold_date_sk, profit_rank
LIMIT 200
