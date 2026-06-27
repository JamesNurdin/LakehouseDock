WITH catalog AS (
    SELECT
        'Catalog' AS channel,
        i.i_category,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt AS discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
store AS (
    SELECT
        'Store' AS channel,
        i.i_category,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt AS discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
web AS (
    SELECT
        'Web' AS channel,
        i.i_category,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
all_sales AS (
    SELECT channel, i_category, net_profit, quantity, discount FROM catalog
    UNION ALL
    SELECT channel, i_category, net_profit, quantity, discount FROM store
    UNION ALL
    SELECT channel, i_category, net_profit, quantity, discount FROM web
)
SELECT
    channel,
    i_category,
    sum(net_profit) AS total_net_profit,
    sum(quantity) AS total_quantity,
    sum(discount) AS total_discount_amount,
    avg(discount / nullif(quantity, 0)) AS avg_discount_per_item
FROM all_sales
GROUP BY channel, i_category
ORDER BY channel, total_net_profit DESC
