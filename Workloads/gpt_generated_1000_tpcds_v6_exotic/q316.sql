WITH filtered_date AS (
    SELECT d_date_sk,
           d_year
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 2000
),
catalog_agg AS (
    SELECT fd.d_year,
           cp.cp_department AS region,
           SUM(cs.cs_net_paid)   AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN filtered_date fd ON cs.cs_sold_date_sk = fd.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY fd.d_year, cp.cp_department
    HAVING SUM(cs.cs_net_paid) > 50000
),
store_agg AS (
    SELECT fd.d_year,
           s.s_state AS region,
           SUM(ss.ss_net_paid)   AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN filtered_date fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY fd.d_year, s.s_state
    HAVING SUM(ss.ss_net_paid) > 50000
),
combined AS (
    SELECT 'catalog' AS source_type,
           d_year,
           region,
           total_net_paid,
           total_profit,
           CASE WHEN total_profit > 100000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_agg
    UNION ALL
    SELECT 'store' AS source_type,
           d_year,
           region,
           total_net_paid,
           total_profit,
           CASE WHEN total_profit > 100000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_agg
)
SELECT source_type,
       d_year AS year,
       region,
       total_net_paid,
       total_profit,
       profit_category,
       ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rank_year
FROM combined
ORDER BY total_net_paid DESC
LIMIT 100
