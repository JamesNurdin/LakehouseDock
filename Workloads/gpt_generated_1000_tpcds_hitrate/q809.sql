WITH sales_enriched AS (
    SELECT
        cs.cs_sold_date_sk,
        d_sold.d_date AS sold_date,
        cp.cp_department,
        cp.cp_description,
        ws.web_name,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        LAG(cs.cs_net_paid_inc_ship) OVER (
            PARTITION BY cp.cp_department
            ORDER BY d_sold.d_date
        ) AS prev_paid_inc_ship,
        SUM(cs.cs_ext_sales_price) OVER (
            PARTITION BY cp.cp_department
            ORDER BY d_sold.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_sales,
        extracted.desc_number
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_page_start
        ON cp.cp_start_date_sk = d_page_start.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_page_start.d_date_sk
    LEFT JOIN LATERAL (
        SELECT regexp_extract(cp.cp_description, '(\\d+)', 1) AS desc_number
    ) AS extracted ON TRUE
    WHERE regexp_like(cp.cp_description, '^.*sale.*$')
      AND ws.web_name LIKE '%Online%'
      AND d_sold.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    cp_department,
    web_name,
    SUM(ext_sales)          AS total_sales,
    SUM(ext_profit)         AS total_profit,
    COUNT(*)                AS transaction_cnt,
    GROUPING(cp_department) AS grp_department,
    GROUPING(web_name)      AS grp_web_name
FROM (
    SELECT
        cp_department,
        web_name,
        cs_ext_sales_price AS ext_sales,
        cs_net_profit       AS ext_profit
    FROM sales_enriched
) s
GROUP BY GROUPING SETS (
    (cp_department, web_name),
    (cp_department),
    (web_name),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
