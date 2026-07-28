WITH store_profit AS (
    SELECT s.s_state AS segment,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2020
    GROUP BY s.s_state
),
catalog_profit AS (
    SELECT cp.cp_department AS segment,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2020
    GROUP BY cp.cp_department
)
SELECT segment, total_profit
FROM store_profit
UNION ALL
SELECT segment, total_profit
FROM catalog_profit
ORDER BY total_profit DESC
LIMIT 100
