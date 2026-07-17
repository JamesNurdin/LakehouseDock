WITH monthly_profit AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS monthly_net_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'Electronics'
      AND d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2001-01-01'
    GROUP BY cp.cp_catalog_page_id, d.d_year, d.d_month_seq
)
SELECT
    cp_catalog_page_id AS catalog_page_id,
    AVG(monthly_net_profit) AS avg_monthly_net_profit,
    COUNT(*) AS month_count
FROM monthly_profit
GROUP BY cp_catalog_page_id
HAVING AVG(monthly_net_profit) > 5000
ORDER BY avg_monthly_net_profit DESC
LIMIT 10
