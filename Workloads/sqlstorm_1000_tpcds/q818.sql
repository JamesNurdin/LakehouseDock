WITH sales_by_channel AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_sales_price) AS revenue
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_color = 'Blue' AND i.i_size LIKE 'MEDIUM%'
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_sales_price) AS revenue
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_color = 'Blue' AND i.i_size LIKE 'MEDIUM%'
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_sales_price) AS revenue
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_color = 'Blue' AND i.i_size LIKE 'MEDIUM%'
    GROUP BY d.d_year, d.d_moy, i.i_category
),
channel_totals AS (
    SELECT
        d_year,
        month,
        i_category,
        SUM(CASE WHEN channel = 'catalog' THEN net_profit ELSE 0 END) AS catalog_profit,
        SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS store_profit,
        SUM(CASE WHEN channel = 'web' THEN net_profit ELSE 0 END) AS web_profit,
        SUM(revenue) AS total_revenue
    FROM sales_by_channel
    GROUP BY d_year, month, i_category
),
ranked AS (
    SELECT
        d_year,
        month,
        i_category,
        catalog_profit,
        store_profit,
        web_profit,
        total_revenue,
        (catalog_profit + store_profit + web_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year, month ORDER BY (catalog_profit + store_profit + web_profit) DESC) AS category_rank,
        SUM(catalog_profit + store_profit + web_profit) OVER (PARTITION BY i_category ORDER BY d_year, month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM channel_totals
)
SELECT
    d_year,
    month,
    i_category,
    total_profit,
    total_revenue,
    catalog_profit,
    store_profit,
    web_profit,
    CAST(catalog_profit * 100.0 / total_profit AS decimal(5,2)) AS catalog_pct,
    CAST(store_profit * 100.0 / total_profit AS decimal(5,2)) AS store_pct,
    CAST(web_profit * 100.0 / total_profit AS decimal(5,2)) AS web_pct,
    category_rank,
    cumulative_profit
FROM ranked
WHERE category_rank <= 5
ORDER BY d_year, month, category_rank
