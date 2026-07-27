WITH store_sales_summary AS (
    SELECT
        d.d_year AS year,
        s.s_store_name AS store_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_profit) > 1000000 THEN 'HIGH'
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_store_name
),
catalog_sales_summary AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) > 2000000 THEN 'HIGH'
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cp.cp_department IN ('Books', 'Electronics')
    GROUP BY d.d_year, cp.cp_department
)
SELECT
    year,
    store_name AS entity,
    total_net_paid,
    total_profit,
    profit_category,
    'STORE' AS source
FROM store_sales_summary
UNION ALL
SELECT
    year,
    department AS entity,
    total_net_paid,
    total_profit,
    profit_category,
    'CATALOG' AS source
FROM catalog_sales_summary
ORDER BY year DESC, total_profit DESC
LIMIT 100
