WITH overall_avg AS (
    SELECT avg(cs2.cs_net_profit) AS avg_profit
    FROM catalog_sales cs2
)
SELECT *
FROM (
    SELECT
        cp.cp_department AS department,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(*) AS sales_cnt,
        min(regexp_extract(cp.cp_description, '(\\w+)', 1)) AS sample_word,
        (SELECT avg_profit FROM overall_avg) AS overall_avg_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(cp.cp_description, '(?i)clear')
      AND cp.cp_description LIKE '%hands%'
      AND d.d_current_quarter = 'Y'
    GROUP BY cp.cp_department

    UNION ALL

    SELECT
        cp.cp_department AS department,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(*) AS sales_cnt,
        min(regexp_extract(cp.cp_description, '(\\w+)', 1)) AS sample_word,
        (SELECT avg_profit FROM overall_avg) AS overall_avg_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(cp.cp_description, '(?i)basic')
      AND cp.cp_description LIKE '%characters%'
      AND d.d_current_quarter = 'N'
    GROUP BY cp.cp_department
) AS q
ORDER BY total_net_profit DESC
LIMIT 100
