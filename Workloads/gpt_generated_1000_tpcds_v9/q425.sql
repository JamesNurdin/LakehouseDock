WITH monthly_sales AS (
    SELECT
        d.d_fy_year AS fy_year,
        d.d_month_seq AS month_seq,
        SUM(s.ss_ext_sales_price) AS total_sales_price,
        SUM(s.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales s
    JOIN date_dim d
        ON s.ss_sold_date_sk = d.d_date_sk
    WHERE s.ss_ext_list_price > 1000
      AND s.ss_net_profit > 0
      AND d.d_fy_year BETWEEN 1905 AND 1915
      AND d.d_moy >= 4
    GROUP BY GROUPING SETS ((d.d_fy_year, d.d_month_seq), (d.d_fy_year))
)
SELECT
    fy_year,
    AVG(total_net_profit) AS avg_monthly_net_profit,
    SUM(total_sales_price) AS annual_sales,
    SUM(total_net_profit) AS annual_net_profit,
    (SUM(total_net_profit) / NULLIF(SUM(total_sales_price), 0)) AS profit_margin
FROM monthly_sales
WHERE month_seq IS NOT NULL
GROUP BY fy_year
HAVING (SUM(total_net_profit) / NULLIF(SUM(total_sales_price), 0)) > 0.05
ORDER BY profit_margin DESC
LIMIT 100
