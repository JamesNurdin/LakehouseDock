WITH store_agg AS (
    SELECT
        'store' AS sales_channel,
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY ROLLUP (d.d_year, i.i_category)
),
catalog_agg AS (
    SELECT
        'catalog' AS sales_channel,
        d.d_year,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ROLLUP (d.d_year, i.i_category)
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT
    sales_channel,
    d_year,
    i_category,
    total_net_profit,
    total_sales,
    SUM(total_net_profit) OVER (PARTITION BY sales_channel ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM combined
ORDER BY sales_channel, d_year, i_category
LIMIT 100
