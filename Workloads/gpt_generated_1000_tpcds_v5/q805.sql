WITH billed AS (
    SELECT
        t.t_hour,
        t.t_sub_shift,
        cd.cd_credit_rating,
        CASE
            WHEN cd.cd_credit_rating = 'Good' THEN 'High'
            WHEN cd.cd_credit_rating = 'Low Risk' THEN 'Medium'
            ELSE 'Low'
        END AS rating_category,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_list_price > 20
      AND t.t_hour BETWEEN 8 AND 20
      AND cd.cd_dep_count <= 2
),
shipping AS (
    SELECT
        t.t_hour,
        t.t_sub_shift,
        cd.cd_credit_rating,
        CASE
            WHEN cd.cd_credit_rating = 'Good' THEN 'High'
            WHEN cd.cd_credit_rating = 'Low Risk' THEN 'Medium'
            ELSE 'Low'
        END AS rating_category,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ws.ws_ship_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_list_price > 20
      AND t.t_hour BETWEEN 8 AND 20
      AND cd.cd_dep_count <= 2
)
SELECT
    source_type,
    t_hour,
    t_sub_shift,
    rating_category,
    COUNT(DISTINCT ws_net_profit) AS distinct_profit_count,
    AVG(ws_net_profit) AS avg_net_profit
FROM (
    SELECT 'billing'   AS source_type, t_hour, t_sub_shift, rating_category, ws_net_profit FROM billed
    UNION ALL
    SELECT 'shipping' AS source_type, t_hour, t_sub_shift, rating_category, ws_net_profit FROM shipping
) AS combined
GROUP BY source_type, t_hour, t_sub_shift, rating_category
ORDER BY source_type, avg_net_profit DESC
LIMIT 100
