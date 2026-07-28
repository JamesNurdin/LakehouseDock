WITH filtered_catalog AS (
    SELECT
        d.d_year AS year,
        cp.cp_department AS department,
        cs.cs_ext_sales_price AS ext_sales,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 1 ELSE 0 END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)\\b(shop|store)\\b')
)
SELECT
    year,
    department,
    SUM(ext_sales) AS total_sales,
    SUM(net_profit) AS total_profit,
    SUM(profit_flag) AS positive_profit_count,
    CASE WHEN SUM(net_profit) > 0 THEN 'Overall Positive' ELSE 'Overall Non-Positive' END AS profit_status,
    concat(department, '-', cast(year AS varchar)) AS dept_year
FROM (
    SELECT
        year,
        department,
        ext_sales,
        net_profit,
        profit_flag
    FROM filtered_catalog
    UNION ALL
    SELECT
        d.d_year AS year,
        'Web' AS department,
        ws.ws_ext_sales_price AS ext_sales,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END AS profit_flag
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE cast(d.d_year AS varchar) LIKE '20%'
) AS combined
GROUP BY GROUPING SETS (
    (year, department),
    (year),
    (department),
    ()
)
ORDER BY year DESC NULLS LAST, department
LIMIT 100
