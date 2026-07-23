WITH store_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        CAST('Store' AS VARCHAR) AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_product_name
),
catalog_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CAST('Catalog' AS VARCHAR) AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    agg.i_item_sk,
    agg.i_product_name,
    agg.total_net_profit,
    agg.sales_channel
FROM (
    SELECT i_item_sk, i_product_name, total_net_profit, sales_channel FROM store_sales_agg
    UNION ALL
    SELECT i_item_sk, i_product_name, total_net_profit, sales_channel FROM catalog_sales_agg
) agg
ORDER BY agg.total_net_profit DESC
LIMIT 20
