WITH
    store_profit AS (
        SELECT
            s.s_store_id,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY s.s_store_id
    ),
    catalog_page_profit AS (
        SELECT
            cp.cp_catalog_page_id,
            SUM(cs.cs_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY cp.cp_catalog_page_id
    ),
    avg_store_profit AS (
        SELECT AVG(total_net_profit) AS avg_profit FROM store_profit
    )
SELECT
    'store' AS source,
    sp.s_store_id AS id,
    sp.total_net_profit,
    sp.sales_cnt
FROM store_profit sp
WHERE sp.total_net_profit > (SELECT avg_profit FROM avg_store_profit)
UNION ALL
SELECT
    'catalog_page' AS source,
    cpp.cp_catalog_page_id AS id,
    cpp.total_net_profit,
    cpp.sales_cnt
FROM catalog_page_profit cpp
WHERE EXISTS (
    SELECT 1
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_net_profit) > cpp.total_net_profit
)
ORDER BY source, total_net_profit DESC
