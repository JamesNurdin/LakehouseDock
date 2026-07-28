WITH recent_dates AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
),
store_profit AS (
    SELECT
        s.s_city AS category,
        'store' AS source,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN recent_dates d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_quantity > 2
    GROUP BY s.s_city
),
catalog_profit AS (
    SELECT
        cp.cp_department AS category,
        'catalog' AS source,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN recent_dates d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_quantity > 2
    GROUP BY cp.cp_department
)
SELECT category, source, total_profit
FROM store_profit
UNION ALL
SELECT category, source, total_profit
FROM catalog_profit
ORDER BY total_profit DESC
LIMIT 100
