WITH store AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        i.i_product_name AS i_product_name,
        t.t_hour AS t_hour,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
),
catalog AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        i.i_product_name AS i_product_name,
        t.t_hour AS t_hour,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
),
web AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        i.i_product_name AS i_product_name,
        t.t_hour AS t_hour,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
),
combined AS (
    SELECT i_item_sk, i_product_name, t_hour, net_profit, channel FROM store
    UNION ALL
    SELECT i_item_sk, i_product_name, t_hour, net_profit, channel FROM catalog
    UNION ALL
    SELECT i_item_sk, i_product_name, t_hour, net_profit, channel FROM web
)
SELECT
    i_item_sk,
    i_product_name,
    t_hour,
    SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY i_item_sk, i_product_name, t_hour
ORDER BY total_net_profit DESC
LIMIT 10
