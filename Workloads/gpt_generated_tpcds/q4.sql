WITH combined_sales AS (
    -- Store sales rows for 2020
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_net_profit AS store_net_profit,
        CAST(NULL AS decimal(7,2)) AS web_net_paid,
        CAST(NULL AS decimal(7,2)) AS web_net_profit,
        CAST(NULL AS decimal(7,2)) AS catalog_net_paid,
        CAST(NULL AS decimal(7,2)) AS catalog_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL

    -- Web sales rows for 2020
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        CAST(NULL AS decimal(7,2)) AS store_net_paid,
        CAST(NULL AS decimal(7,2)) AS store_net_profit,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_net_profit AS web_net_profit,
        CAST(NULL AS decimal(7,2)) AS catalog_net_paid,
        CAST(NULL AS decimal(7,2)) AS catalog_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'

    UNION ALL

    -- Catalog sales rows for 2020
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_category AS category,
        CAST(NULL AS decimal(7,2)) AS store_net_paid,
        CAST(NULL AS decimal(7,2)) AS store_net_profit,
        CAST(NULL AS decimal(7,2)) AS web_net_paid,
        CAST(NULL AS decimal(7,2)) AS web_net_profit,
        cs.cs_net_paid AS catalog_net_paid,
        cs.cs_net_profit AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
),
aggregated_sales AS (
    SELECT
        year,
        month_seq,
        category,
        SUM(store_net_paid) AS store_net_paid,
        SUM(store_net_profit) AS store_net_profit,
        SUM(web_net_paid) AS web_net_paid,
        SUM(web_net_profit) AS web_net_profit,
        SUM(catalog_net_paid) AS catalog_net_paid,
        SUM(catalog_net_profit) AS catalog_net_profit,
        (SUM(store_net_paid) + SUM(web_net_paid) + SUM(catalog_net_paid)) AS total_net_paid,
        (SUM(store_net_profit) + SUM(web_net_profit) + SUM(catalog_net_profit)) AS total_net_profit
    FROM combined_sales
    GROUP BY
        year,
        month_seq,
        category
)
SELECT
    year,
    month_seq,
    category,
    store_net_paid,
    store_net_profit,
    web_net_paid,
    web_net_profit,
    catalog_net_paid,
    catalog_net_profit,
    total_net_paid,
    total_net_profit,
    RANK() OVER (PARTITION BY year, month_seq ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated_sales
ORDER BY
    year,
    month_seq,
    profit_rank
