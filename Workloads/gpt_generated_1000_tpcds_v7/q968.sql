WITH combined_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        cs.cs_net_profit AS net_profit
    FROM
        catalog_sales cs
        INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2020
    UNION ALL
    SELECT
        i.i_item_sk,
        i.i_product_name,
        ws.ws_net_profit AS net_profit
    FROM
        web_sales ws
        INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2020
)
SELECT
    i_item_sk,
    i_product_name,
    SUM(net_profit) AS total_net_profit
FROM
    combined_sales
GROUP BY
    i_item_sk,
    i_product_name
ORDER BY
    total_net_profit DESC
LIMIT 10
