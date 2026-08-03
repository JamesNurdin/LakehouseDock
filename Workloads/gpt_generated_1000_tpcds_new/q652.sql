WITH sales_data AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        t.t_hour
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_net_profit IS NOT NULL
),
unioned AS (
    SELECT sd.ss_store_sk AS store_sk,
        SUM(sd.ss_net_profit) AS total_profit
    FROM sales_data sd
    WHERE sd.cd_gender = 'M'
        AND sd.t_hour BETWEEN 9 AND 12
    GROUP BY sd.ss_store_sk
    HAVING SUM(sd.ss_net_profit) > 500
    UNION
    SELECT sd.ss_store_sk AS store_sk,
        SUM(sd.ss_net_profit) AS total_profit
    FROM sales_data sd
    WHERE sd.cd_gender = 'F'
        AND sd.t_hour BETWEEN 13 AND 17
    GROUP BY sd.ss_store_sk
    HAVING SUM(sd.ss_net_profit) > 500
),
common_stores AS (
    SELECT u.store_sk
    FROM (SELECT store_sk FROM unioned) u
    INTERSECT
    SELECT sd.ss_store_sk
    FROM sales_data sd
    WHERE sd.t_hour BETWEEN 9 AND 17
    GROUP BY sd.ss_store_sk
    HAVING SUM(sd.ss_net_profit) > 2000
)
SELECT u.store_sk,
    u.total_profit
FROM unioned u
JOIN common_stores cs ON u.store_sk = cs.store_sk
ORDER BY u.total_profit DESC
LIMIT 10
